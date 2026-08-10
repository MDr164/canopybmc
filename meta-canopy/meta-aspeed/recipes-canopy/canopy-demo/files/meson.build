project(
    'canopy-demo-mock',
    'cpp',
    version: '1.0',
    default_options: [
        'cpp_std=c++23',
        'warning_level=3',
        'werror=false',
    ],
)

deps = [
    dependency('sdbusplus'),
    dependency('boost'),
]

executable(
    'canopy-demo-mock',
    ['main.cpp'],
    dependencies: deps,
    install: true,
    install_dir: get_option('bindir'),
)
