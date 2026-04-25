import copy


class InheritableMeta(type):
    """Metaclass that enables += on class attributes with proper inheritance.

    Without this metaclass, `tag += ["x"]` in a child class body would
    mutate the parent's list in-place. This metaclass copies all
    inheritable attributes from parent into the child's namespace
    before the class body executes, so += creates independent copies.
    """

    @classmethod
    def __prepare__(mcs, name, bases, **kwargs):
        namespace = super().__prepare__(name, bases, **kwargs)
        if bases:
            parent = bases[0]
            for key, value in parent.__dict__.items():
                if key.startswith("_"):
                    continue
                if isinstance(value, list):
                    namespace[key] = list(value)
                elif isinstance(value, dict):
                    namespace[key] = dict(value)
                else:
                    namespace[key] = value
        return namespace


class Build(metaclass=InheritableMeta):
    """Base class for VCS build configurations."""
    name = ""
    tag = []
    vlog_opt = ""
    elab_opt = ""
    simulator = "vcs"


class Test(metaclass=InheritableMeta):
    """Base class for simulation test cases."""
    name = ""
    tag = []
    uvm_test = ""
    sim_opt = ""
    c_test = ""
    c_defines = {}
    build = None
    prerun_script = ""
    postrun_script = ""

    def get_prerun_script(self, out_dir):
        """Return the prerun script command.

        If prerun_script is set, use it (with {name} substitution).
        Otherwise, auto-generate from c_test and c_defines.
        """
        if self.prerun_script:
            return self.prerun_script.replace("{name}", self.name)

        if not self.c_test:
            return ""

        fw_out = f"{out_dir}/{self.name}/fw"
        cmd = f"make -C ../c CTEST={self.c_test} OUT={fw_out} all"
        if self.c_defines:
            defines = " ".join(f"-D{k}={v}" for k, v in self.c_defines.items())
            cmd += f' CFLAGS+="{defines}"'
        return cmd
