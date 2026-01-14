
// src/hello.c
#include <emacs-module.h>
#include <string.h>   // for strlen

int plugin_is_GPL_compatible;

/* (cext-hello)
   Returns the string "Hello, Emacs, this is C" to Lisp. */
static emacs_value F_cext_hello(emacs_env *env,
                                ptrdiff_t nargs,
                                emacs_value args[],
                                void *data) {
    (void)nargs;
    (void)args;
    (void)data;

    const char *msg = "Hello, Emacs, this is C";
    /* Create an Emacs string value and return it. */
    return env->make_string(env, msg, (ptrdiff_t)strlen(msg));
}

int emacs_module_init(struct emacs_runtime *ert) {
    emacs_env *env = ert->get_environment(ert);

    /* Define the function under the symbol `cext-hello`. */
    emacs_value Qfset = env->intern(env, "fset");
    emacs_value Qsym  = env->intern(env, "cext-hello");
    emacs_value func  = env->make_function(
        env,
        /* min/max args */ 0, 0,
        /* C entry point */ F_cext_hello,
        /* docstring */     "Return a hello string from the C module.",
        /* user data */     NULL
    );

    emacs_value set_args[2] = { Qsym, func };
    env->funcall(env, Qfset, 2, set_args);

    /* Optionally provide a feature so you can (require 'cext) if you add an .el wrapper. */
    emacs_value Qprovide = env->intern(env, "provide");
    emacs_value Qfeat    = env->intern(env, "cext");
    env->funcall(env, Qprovide, 1, &Qfeat);

    return 0; /* success */
}
