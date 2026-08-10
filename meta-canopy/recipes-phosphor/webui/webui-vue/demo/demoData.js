// Canopy demo UI mode: hardcoded Redfish responses.
//
// Keyed by request path (query string and trailing slash are ignored by the
// mock adapter). Values may be plain objects or functions (config) => object
// for anything that should be computed at request time (e.g. current time).
//
// Only the endpoints the dashboard (and common navigation) touch are defined;
// anything else falls back to a permissive empty collection in mockAdapter.js.
// Edit the values here to change what the demo dashboard shows.

const systemPath = '/redfish/v1/Systems/system';
const bmcPath = '/redfish/v1/Managers/bmc';

const bmcActiveFwId = 'bmc_active';
const bmcBackupFwId = 'bmc_backup';

// ---- inventory / identity ------------------------------------------------

const system = {
  '@odata.id': systemPath,
  '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
  Id: 'system',
  Name: 'Canopy Demo Server',
  SystemType: 'Physical',
  Manufacturer: 'Canopy',
  Model: 'Canopy Demo Server',
  SubModel: 'Performance',
  SerialNumber: 'DEMO0000001',
  PartNumber: 'CNPY-DCSCM-2700',
  AssetTag: 'CANOPY-DEMO-001',
  BiosVersion: 'C2026.01.01',
  PowerState: 'On',
  Status: { State: 'Enabled', Health: 'OK', HealthRollup: 'OK' },
  ProcessorSummary: {
    Count: 2,
    CoreCount: 128,
    Model: 'Canopy Demo CPU @ 3.20GHz',
    Status: { State: 'Enabled', Health: 'OK' },
  },
  MemorySummary: {
    TotalSystemMemoryGiB: 512,
    Status: { State: 'Enabled', Health: 'OK' },
  },
  LocationIndicatorActive: false,
  Location: { PartLocation: { ServiceLabel: 'Rack 1, U10' } },
  SerialConsole: { ServiceEnabled: true, MaxConcurrentSessions: 1 },
  Bios: { '@odata.id': `${systemPath}/Bios` },
};

const systemBios = {
  '@odata.id': `${systemPath}/Bios`,
  Id: 'Bios',
  Links: {
    ActiveSoftwareImage: {
      '@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/bios_active',
    },
  },
};

// ---- managers / firmware / time ------------------------------------------

const bmc = {
  '@odata.id': bmcPath,
  '@odata.type': '#Manager.v1_15_0.Manager',
  Id: 'bmc',
  Name: 'OpenBmc Manager',
  ManagerType: 'BMC',
  Model: 'Canopy BMC',
  FirmwareVersion: 'canopy-2026.06',
  DateTime: () => new Date().toISOString(),
  Status: { State: 'Enabled', Health: 'OK' },
  Links: {
    ActiveSoftwareImage: {
      '@odata.id': `/redfish/v1/UpdateService/FirmwareInventory/${bmcActiveFwId}`,
    },
  },
};

const firmwareInventory = {
  '@odata.id': '/redfish/v1/UpdateService/FirmwareInventory',
  Members: [
    { '@odata.id': `/redfish/v1/UpdateService/FirmwareInventory/${bmcActiveFwId}` },
    { '@odata.id': `/redfish/v1/UpdateService/FirmwareInventory/${bmcBackupFwId}` },
  ],
  'Members@odata.count': 2,
};

const fwImage = (id, version) => ({
  '@odata.id': `/redfish/v1/UpdateService/FirmwareInventory/${id}`,
  Id: id,
  Version: version,
  Status: { State: 'Enabled', Health: 'OK' },
  RelatedItem: [{ '@odata.id': bmcPath }],
});

const updateService = {
  '@odata.id': '/redfish/v1/UpdateService',
  HttpPushUri: '/redfish/v1/UpdateService/update',
  MultipartHttpPushUri: '/redfish/v1/UpdateService/update-multipart',
  HttpPushUriOptions: {
    HttpPushUriApplyTime: { ApplyTime: 'Immediate' },
  },
  FirmwareInventory: { '@odata.id': '/redfish/v1/UpdateService/FirmwareInventory' },
};

// ---- network -------------------------------------------------------------

const ethInterface = {
  '@odata.id': `${bmcPath}/EthernetInterfaces/eth0`,
  Id: 'eth0',
  Name: 'Manager Ethernet Interface',
  HostName: 'canopy-demo',
  MACAddress: '02:42:AC:11:00:2A',
  LinkStatus: 'LinkUp',
  DHCPv4: {
    DHCPEnabled: true,
    UseDNSServers: true,
    UseDomainName: true,
    UseNTPServers: true,
  },
  DHCPv6: {
    OperatingMode: 'Enabled',
    UseDNSServers: true,
    UseDomainName: true,
    UseNTPServers: true,
  },
  IPv4Addresses: [
    {
      Address: '10.0.0.42',
      SubnetMask: '255.255.255.0',
      AddressOrigin: 'DHCP',
      Gateway: '10.0.0.1',
    },
  ],
  IPv4StaticAddresses: [],
  IPv6Addresses: [
    { Address: 'fe80::42', PrefixLength: 64, AddressOrigin: 'SLAAC' },
  ],
  IPv6StaticAddresses: [],
  IPv6DefaultGateway: 'fe80::1',
};

// ---- event log -----------------------------------------------------------

const now = Date.now();
const iso = (msAgo) => new Date(now - msAgo).toISOString();

const eventLogEntries = {
  '@odata.id': `${systemPath}/LogServices/EventLog/Entries`,
  Members: [
    {
      '@odata.id': `${systemPath}/LogServices/EventLog/Entries/1`,
      Id: '1',
      Name: 'System Event Log Entry',
      EntryType: 'Event',
      Severity: 'OK',
      Created: iso(1000 * 60 * 42),
      Modified: iso(1000 * 60 * 42),
      Message: 'Host system powered on and reached OS.',
      Resolved: true,
    },
    {
      '@odata.id': `${systemPath}/LogServices/EventLog/Entries/2`,
      Id: '2',
      Name: 'System Event Log Entry',
      EntryType: 'Event',
      Severity: 'Warning',
      Created: iso(1000 * 60 * 18),
      Modified: iso(1000 * 60 * 18),
      Message: 'Inlet temperature approaching upper non-critical threshold.',
      Resolved: false,
    },
    {
      '@odata.id': `${systemPath}/LogServices/EventLog/Entries/3`,
      Id: '3',
      Name: 'System Event Log Entry',
      EntryType: 'Event',
      Severity: 'OK',
      Created: iso(1000 * 60 * 5),
      Modified: iso(1000 * 60 * 5),
      Message: 'BMC time synchronized with NTP server.',
      Resolved: true,
    },
  ],
  'Members@odata.count': 3,
};

// ---- chassis / power -----------------------------------------------------

const chassisPath = '/redfish/v1/Chassis/chassis';

const chassis = {
  '@odata.id': chassisPath,
  '@odata.type': '#Chassis.v1_25_0.Chassis',
  Id: 'chassis',
  Name: 'Canopy Demo Chassis',
  ChassisType: 'RackMount',
  Manufacturer: 'Canopy',
  Model: 'Canopy Demo Chassis',
  SerialNumber: 'DEMO0000001',
  PowerState: 'On',
  Status: { State: 'Enabled', Health: 'OK' },
  EnvironmentMetrics: { '@odata.id': `${chassisPath}/EnvironmentMetrics` },
};

const environmentMetrics = {
  '@odata.id': `${chassisPath}/EnvironmentMetrics`,
  Id: 'EnvironmentMetrics',
  PowerWatts: { Reading: 415, DataSourceUri: `${chassisPath}/Sensors/total_power` },
  PowerLimitWatts: { SetPoint: 800, ControlMode: 'Automatic' },
};

// ---- service root & collections ------------------------------------------

const serviceRoot = {
  '@odata.id': '/redfish/v1',
  '@odata.type': '#ServiceRoot.v1_15_0.ServiceRoot',
  Id: 'RootService',
  Name: 'Root Service',
  RedfishVersion: '1.17.0',
  ManagerProvidingService: { '@odata.id': bmcPath },
  Systems: { '@odata.id': '/redfish/v1/Systems' },
  Chassis: { '@odata.id': '/redfish/v1/Chassis' },
  Managers: { '@odata.id': '/redfish/v1/Managers' },
  SessionService: { '@odata.id': '/redfish/v1/SessionService' },
  AccountService: { '@odata.id': '/redfish/v1/AccountService' },
  UpdateService: { '@odata.id': '/redfish/v1/UpdateService' },
  EventService: { '@odata.id': '/redfish/v1/EventService' },
  // Note: no ProtocolFeaturesSupported.ExpandQuery, so the UI fetches
  // collection members individually (which the mock adapter serves).
};

const collection = (id, memberIds) => ({
  '@odata.id': id,
  Members: memberIds.map((m) => ({ '@odata.id': m })),
  'Members@odata.count': memberIds.length,
});

const demoResponses = {
  '/redfish/v1': serviceRoot,

  '/redfish/v1/Systems': collection('/redfish/v1/Systems', [systemPath]),
  [systemPath]: system,
  [`${systemPath}/Bios`]: systemBios,
  [`${systemPath}/LogServices/EventLog/Entries`]: eventLogEntries,

  '/redfish/v1/Managers': collection('/redfish/v1/Managers', [bmcPath]),
  [bmcPath]: bmc,
  [`${bmcPath}/EthernetInterfaces`]: collection(
    `${bmcPath}/EthernetInterfaces`,
    [`${bmcPath}/EthernetInterfaces/eth0`],
  ),
  [`${bmcPath}/EthernetInterfaces/eth0`]: ethInterface,

  '/redfish/v1/Chassis': collection('/redfish/v1/Chassis', [chassisPath]),
  [chassisPath]: chassis,
  [`${chassisPath}/EnvironmentMetrics`]: environmentMetrics,

  '/redfish/v1/UpdateService': updateService,
  '/redfish/v1/UpdateService/FirmwareInventory': firmwareInventory,
  [`/redfish/v1/UpdateService/FirmwareInventory/${bmcActiveFwId}`]: fwImage(
    bmcActiveFwId,
    'canopy-2026.06',
  ),
  [`/redfish/v1/UpdateService/FirmwareInventory/${bmcBackupFwId}`]: fwImage(
    bmcBackupFwId,
    'canopy-2026.04',
  ),
};

export default demoResponses;
