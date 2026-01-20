
#include <emacs-module.h>
#include <string.h>

int plugin_is_GPL_compatible;

static emacs_value F_cext_hello(emacs_env *env, ptrdiff_t nargs,
                                emacs_value args[], void *data) {
  (void)nargs;
  (void)args;
  (void)data;
  const char *msg = "Hello, Emacs, this is C";
  return env->make_string(env, msg, (ptrdiff_t)strlen(msg));
}

int emacs_module_init(struct emacs_runtime *ert) {
  emacs_env *env = ert->get_environment(ert);

  // Create the function object
  emacs_value fn =
      env->make_function(env, 0, 0, F_cext_hello,
                         "Return a hello string from the C module.", NULL);

  // Bind it to a *variable*, not a function cell.
  emacs_value Qsym = env->intern(env, "--c-ext-bootstrap--hello-fn");
  emacs_value Qset = env->intern(env, "set");
  emacs_value args[2] = {Qsym, fn};
  env->funcall(env, Qset, 2, args);

  return 0;
}
