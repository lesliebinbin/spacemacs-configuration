emacs_include = include_directories('/usr/local/include')

src_files = ['src/module.c']

bootstrap_plugin = shared_library('module',
                                     src_files,
                                     include_directories: [emacs_include],
                                     install: true,
                                     version: meson.project_version())

bootstrap_plugin_dep = declare_dependency(include_directories: emacs_include,
                                         link_with: bootstrap_plugin)
