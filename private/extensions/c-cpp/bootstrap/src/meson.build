# emacs_lib = meson.get_compiler('c').find_library('emacs', dirs:['/usr/local/lib/emacs'])

emacs_include = include_directories('/usr/local/include')

src_files = ['module.c']

bootstrap_plugin = shared_library('bootstrap',
                                     src_files,
                                     include_directories: [emacs_include],
                                     #dependencies: [emacs_lib],
                                     install: false,
                                     version: meson.project_version())

bootstrap_plugin_dep = declare_dependency(include_directories: emacs_include,
                                         link_with: bootstrap_plugin)
