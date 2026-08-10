// SPDX-License-Identifier: Apache-2.0
//
// canopy-demo-mock: publish fake-but-plausible inventory and sensors on D-Bus so
// the Canopy WebUI dashboard and Redfish show useful data on the AST2700 DC-SCM
// demo target, which has no FRU EEPROM, no reliable host power-on, and no real
// sensors.
//
// This is a demo aid, gated behind canopy-demo mode (see canopy-demo(1)); it is
// never installed on production images. It owns:
//
//   * /xyz/openbmc_project/inventory/system           (System + Asset identity)
//   * /xyz/openbmc_project/inventory/system/chassis    (Chassis/Board + Asset)
//   * /xyz/openbmc_project/sensors/<type>/<name>        (a few live sensors)
//
// bmcweb consumes these exactly as it would real entity-manager / dbus-sensors
// objects, so no WebUI/Redfish changes are needed. Sensor values jitter on a
// timer so the dashboard looks alive.

#include <boost/asio/io_context.hpp>
#include <boost/asio/steady_timer.hpp>
#include <sdbusplus/asio/connection.hpp>
#include <sdbusplus/asio/object_server.hpp>

#include <chrono>
#include <cmath>
#include <memory>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

namespace
{

constexpr const char* busName = "xyz.openbmc_project.CanopyDemo";

// Single inventory object carrying System + Chassis/Board + Asset, mirroring the
// proven entity-manager pattern (see meta-hpe .../dl320g11_baseboard.json) that
// bmcweb reads system identity and chassis from. Sensors associate to it.
constexpr const char* chassisPath =
    "/xyz/openbmc_project/inventory/system/chassis/canopy_demo";

// Association: forward "chassis", reverse "all_sensors", to the chassis object.
using Association = std::tuple<std::string, std::string, std::string>;

// A live sensor: keeps its D-Bus interface so the timer can update Value.
struct Sensor
{
    std::shared_ptr<sdbusplus::asio::dbus_interface> value;
    double base;   // nominal value
    double swing;  // +/- jitter amplitude
    double phase;  // per-sensor phase so they don't move in lock-step
};

std::vector<std::shared_ptr<sdbusplus::asio::dbus_interface>> keepAlive;
std::vector<Sensor> sensors;

// Add an interface with a set of string properties, keeping it alive.
void addStringIface(sdbusplus::asio::object_server& server,
                    const std::string& path, const std::string& iface,
                    std::vector<std::pair<std::string, std::string>> props)
{
    auto i = server.add_interface(path, iface);
    for (auto& [name, val] : props)
    {
        i->register_property(name, val);
    }
    i->initialize();
    keepAlive.push_back(i);
}

void addInventory(sdbusplus::asio::object_server& server)
{
    const std::string serial = "DEMO0000001";
    const std::string part = "CNPY-DCSCM-2700";

    // Marker interfaces: this object is a Board, a Chassis, and the System.
    auto board = server.add_interface(
        chassisPath, "xyz.openbmc_project.Inventory.Item.Board");
    board->initialize();
    keepAlive.push_back(board);

    auto chassis = server.add_interface(
        chassisPath, "xyz.openbmc_project.Inventory.Item.Chassis");
    chassis->register_property(
        std::string("Type"),
        std::string("xyz.openbmc_project.Inventory.Item.Chassis.ChassisType."
                    "RackMount"));
    chassis->initialize();
    keepAlive.push_back(chassis);

    // System identity read by the Redfish/WebUI "Server information" cards.
    addStringIface(server, chassisPath,
                   "xyz.openbmc_project.Inventory.Item.System",
                   {{"PartNumber", part}, {"SerialNumber", serial}});

    auto item =
        server.add_interface(chassisPath, "xyz.openbmc_project.Inventory.Item");
    item->register_property(std::string("PrettyName"),
                            std::string("Canopy Demo Server"));
    item->register_property("Present", true);
    item->initialize();
    keepAlive.push_back(item);

    addStringIface(server, chassisPath,
                   "xyz.openbmc_project.Inventory.Decorator.Asset",
                   {{"Manufacturer", "Canopy"},
                    {"Model", "Canopy Demo Server"},
                    {"PartNumber", part},
                    {"SerialNumber", serial},
                    {"SparePartNumber", "CNPY-DCSCM-2700-SPARE"},
                    {"BuildDate", "2026-01-01T00:00:00Z"}});

    addStringIface(server, chassisPath,
                   "xyz.openbmc_project.Inventory.Decorator.AssetTag",
                   {{"AssetTag", "CANOPY-DEMO-001"}});

    addStringIface(server, chassisPath,
                   "xyz.openbmc_project.Inventory.Decorator.Revision",
                   {{"Version", "1.0"}});
}

void addSensor(sdbusplus::asio::object_server& server, const std::string& ns,
               const std::string& name, const std::string& unit, double base,
               double minV, double maxV, double swing)
{
    const std::string path =
        std::string("/xyz/openbmc_project/sensors/") + ns + "/" + name;

    auto value =
        server.add_interface(path, "xyz.openbmc_project.Sensor.Value");
    value->register_property("Value", base);
    value->register_property("MaxValue", maxV);
    value->register_property("MinValue", minV);
    value->register_property(
        std::string("Unit"),
        std::string("xyz.openbmc_project.Sensor.Value.Unit.") + unit);
    value->initialize();

    auto avail = server.add_interface(
        path, "xyz.openbmc_project.State.Decorator.Availability");
    avail->register_property("Available", true);
    avail->initialize();
    keepAlive.push_back(avail);

    auto oper = server.add_interface(
        path, "xyz.openbmc_project.State.Decorator.OperationalStatus");
    oper->register_property("Functional", true);
    oper->initialize();
    keepAlive.push_back(oper);

    // Tie the sensor to the demo chassis so it shows under that Redfish chassis.
    auto assoc =
        server.add_interface(path, "xyz.openbmc_project.Association.Definitions");
    assoc->register_property(
        "Associations",
        std::vector<Association>{
            Association{"chassis", "all_sensors", chassisPath}});
    assoc->initialize();
    keepAlive.push_back(assoc);

    sensors.push_back(Sensor{value, base, swing,
                             static_cast<double>(sensors.size())});
}

void scheduleJitter(boost::asio::steady_timer& timer)
{
    timer.expires_after(std::chrono::seconds(3));
    timer.async_wait([&timer](const boost::system::error_code& ec) {
        if (ec)
        {
            return;
        }
        static double t = 0.0;
        t += 0.5;
        for (auto& s : sensors)
        {
            double v = s.base + s.swing * std::sin(t + s.phase);
            s.value->set_property("Value", v);
        }
        scheduleJitter(timer);
    });
}

} // namespace

int main()
{
    boost::asio::io_context io;
    auto conn = std::make_shared<sdbusplus::asio::connection>(io);

    sdbusplus::asio::object_server server(conn);
    // Object managers so ObjectMapper (and thus bmcweb) discover the objects.
    server.add_manager("/xyz/openbmc_project/inventory");
    server.add_manager("/xyz/openbmc_project/sensors");

    addInventory(server);

    addSensor(server, "temperature", "CPU0_Temp", "DegreesC", 47.0, 0.0, 105.0,
              4.0);
    addSensor(server, "temperature", "CPU1_Temp", "DegreesC", 45.0, 0.0, 105.0,
              4.0);
    addSensor(server, "temperature", "Inlet_Temp", "DegreesC", 24.0, 0.0, 60.0,
              1.5);
    addSensor(server, "fan_tach", "Fan0", "RPMS", 8200.0, 0.0, 16000.0, 300.0);
    addSensor(server, "fan_tach", "Fan1", "RPMS", 8100.0, 0.0, 16000.0, 300.0);
    addSensor(server, "voltage", "P12V", "Volts", 12.05, 0.0, 14.0, 0.05);
    addSensor(server, "power", "Total_Power", "Watts", 415.0, 0.0, 1600.0,
              25.0);

    boost::asio::steady_timer jitter(io);
    scheduleJitter(jitter);

    // Claim the name last so all objects appear atomically.
    conn->request_name(busName);

    io.run();
    return 0;
}
