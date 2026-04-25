import copy
import os


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

    @classmethod
    def get_prerun_script(cls, out_dir):
        """Return the prerun script command.

        If prerun_script is set, use it (with {name} substitution).
        Otherwise, auto-generate from c_test and c_defines.
        """
        if cls.prerun_script:
            return cls.prerun_script.replace("{name}", cls.name).replace("{out_dir}", out_dir)

        if not cls.c_test:
            return ""

        fw_out = f"{out_dir}/{cls.name}/fw"
        proj_root = os.path.normpath(os.path.join(out_dir, ".."))
        c_dir = os.path.join(proj_root, "c")
        cmd = f"make -C {c_dir} CTEST={cls.c_test} OUT={fw_out} all"
        if cls.c_defines:
            defines = " ".join(f"-D{k}={v}" for k, v in cls.c_defines.items())
            cmd += f' EXTRA_CFLAGS="{defines}"'
        # Copy firmware.slm to l2_stim.slm and create dummy tcdm_bank0.slm
        cmd += f" && cp {fw_out}/firmware.slm {fw_out}/l2_stim.slm"
        cmd += f" && echo '@00000000 00000000' > {fw_out}/tcdm_bank0.slm"
        return cmd
