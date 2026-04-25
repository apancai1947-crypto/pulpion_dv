import hashlib
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed


def compute_build_hash(build_cls, global_opts=""):
    """Compute hash from vlog_opt + elab_opt + simulator + global_opts."""
    content = f"{build_cls.vlog_opt}|{build_cls.elab_opt}|{build_cls.simulator}|{global_opts}"
    return hashlib.md5(content.encode()).hexdigest()[:8]


def get_global_opts(args):
    """Build global option strings from CLI args for vlog and sim."""
    vlog_opts = []
    sim_opts = []

    if args.cov:
        vlog_opts.append("-cm line+cond+fsm+branch+tgl +define+COV")
        sim_opts.append("-cm line+cond+fsm+branch+tgl")
    if args.debug:
        vlog_opts.append("-debug_access+all -kdb -lca")
    if args.xprop:
        vlog_opts.append("-xprop=tmerge")

    return " ".join(vlog_opts), " ".join(sim_opts)


def compile_build(build_cls, out_dir, global_vlog_opts, dry_run=False):
    """Compile a Build, return path to simv directory."""
    build_hash = compute_build_hash(build_cls, global_vlog_opts)
    build_dir = os.path.join(out_dir, f".{build_hash}")

    simv_path = os.path.join(build_dir, "simv")
    if os.path.exists(simv_path):
        print(f"[BUILD] Reusing cached build .{build_hash} ({build_cls.name})")
        return build_dir

    os.makedirs(build_dir, exist_ok=True)

    vlog_opts = f"{build_cls.vlog_opt} {global_vlog_opts}".strip()
    elab_opts = build_cls.elab_opt.strip()

    # Locate filelist.f relative to sim/
    sim_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    filelist = os.path.join(sim_dir, "filelist.f")

    cmd = (
        f"cd {build_dir} && "
        f"vcs {vlog_opts} {elab_opts} "
        f"-f {filelist} "
        f"-top tb_top "
        f"-o simv "
        f"-l compile.log"
    )

    if dry_run:
        print(f"[DRY-RUN] {cmd}")
        return build_dir

    print(f"[BUILD] Compiling .{build_hash} ({build_cls.name})...")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"[BUILD] FAILED .{build_hash}:\n{result.stderr}", file=sys.stderr)
        raise RuntimeError(f"Build failed: {build_cls.name}")

    print(f"[BUILD] Done .{build_hash} ({build_cls.name})")
    return build_dir


def validate_sim_opt(sim_opt):
    """Check sim_opt for forbidden +define+ macros. Return cleaned string."""
    warnings = []
    parts = []
    for opt in sim_opt.split():
        if opt.startswith("+define+"):
            warnings.append(f"WARNING: +define+ not allowed in sim_opt, ignored: {opt}")
        else:
            parts.append(opt)
    return " ".join(parts), warnings


def run_test(test_cls, build_dir, out_dir, global_sim_opts, extra_opts,
             dry_run=False, delete_passed=False):
    """Run a single test case.

    Returns: (test_name, "PASS"|"FAIL", message)
    """
    test_name = test_cls.name
    test_dir = os.path.join(out_dir, test_name)
    os.makedirs(test_dir, exist_ok=True)

    # Copy simv and simv.daidir from build to test directory
    if not dry_run:
        for item in ["simv", "simv.daidir"]:
            src = os.path.join(build_dir, item)
            dst = os.path.join(test_dir, item)
            if not os.path.exists(src):
                continue
            if os.path.isdir(src):
                if os.path.exists(dst):
                    shutil.rmtree(dst)
                shutil.copytree(src, dst)
            else:
                shutil.copy2(src, dst)

    # Prerun
    prerun = test_cls.get_prerun_script(out_dir)
    if prerun:
        if dry_run:
            print(f"[DRY-RUN] [{test_name}] prerun: {prerun}")
        else:
            print(f"[SIM] [{test_name}] Running prerun...")
            result = subprocess.run(prerun, shell=True, capture_output=True, text=True)
            if result.returncode != 0:
                return (test_name, "FAIL", f"prerun failed: {result.stderr[:200]}")

    # Validate sim_opt
    sim_opt_clean, warns = validate_sim_opt(test_cls.sim_opt)
    for w in warns:
        print(f"[SIM] [{test_name}] {w}")

    # Build sim command
    uvm_test_arg = f"+UVM_TESTNAME={test_cls.uvm_test}" if test_cls.uvm_test else ""
    sim_cmd = (
        f"cd {test_dir} && "
        f"./simv "
        f"{sim_opt_clean} "
        f"{uvm_test_arg} "
        f"{global_sim_opts} "
        f"{' '.join(extra_opts)} "
        f"-l simv.log"
    )

    if dry_run:
        print(f"[DRY-RUN] [{test_name}] sim: {sim_cmd}")
        return (test_name, "DRY-RUN", "")

    print(f"[SIM] [{test_name}] Running simulation...")
    result = subprocess.run(sim_cmd, shell=True, capture_output=True, text=True)

    # Determine pass/fail from log
    log_path = os.path.join(test_dir, "simv.log")
    status = "FAIL"
    msg = ""
    if os.path.exists(log_path):
        with open(log_path) as f:
            log_content = f.read()
        if "========== TEST PASSED ==========" in log_content:
            status = "PASS"
        elif "========== TEST FAILED ==========" in log_content:
            status = "FAIL"
            msg = "UVM reported FAIL"
    else:
        msg = "simv.log not found"

    # Postrun
    postrun = test_cls.postrun_script
    if postrun:
        postrun = postrun.replace("{name}", test_name)
        if dry_run:
            print(f"[DRY-RUN] [{test_name}] postrun: {postrun}")
        else:
            subprocess.run(postrun, shell=True, capture_output=True, text=True)

    # Delete passed files if requested
    if delete_passed and status == "PASS" and not dry_run:
        shutil.rmtree(test_dir)
        print(f"[SIM] [{test_name}] PASSED, cleaned output directory")

    print(f"[SIM] [{test_name}] {status}")
    return (test_name, status, msg)


def run_all(tests_to_run, out_dir, args, extra_opts):
    """Main execution: compile builds, run tests in parallel, write results."""
    os.makedirs(out_dir, exist_ok=True)
    global_vlog_opts, global_sim_opts = get_global_opts(args)

    # Collect unique builds and compile
    build_cache = {}
    for test_cls in tests_to_run.values():
        build_cls = test_cls.build
        if build_cls is None:
            print(f"[WARN] Test {test_cls.name} has no build, skipping")
            continue
        if build_cls not in build_cache:
            build_dir = compile_build(build_cls, out_dir, global_vlog_opts,
                                      dry_run=args.dry_run)
            build_cache[build_cls] = build_dir

    # Run tests
    results = []
    if args.dry_run:
        for test_cls in tests_to_run.values():
            build_dir = build_cache.get(test_cls.build)
            if build_dir:
                r = run_test(test_cls, build_dir, out_dir, global_sim_opts,
                             extra_opts, dry_run=True)
                results.append(r)
    else:
        with ThreadPoolExecutor(max_workers=args.j) as executor:
            futures = {}
            for test_cls in tests_to_run.values():
                build_dir = build_cache.get(test_cls.build)
                if not build_dir:
                    continue
                future = executor.submit(
                    run_test, test_cls, build_dir, out_dir,
                    global_sim_opts, extra_opts,
                    dry_run=False, delete_passed=args.delete_passed_files
                )
                futures[future] = test_cls.name

            for future in as_completed(futures):
                results.append(future.result())

    # Write results.log
    results_path = os.path.join(out_dir, "results.log")
    passed = sum(1 for _, s, _ in results if s == "PASS")
    failed = sum(1 for _, s, _ in results if s == "FAIL")
    with open(results_path, "w") as f:
        f.write(f"Total: {len(results)}  Passed: {passed}  Failed: {failed}\n")
        f.write("-" * 60 + "\n")
        for name, status, msg in results:
            line = f"  {status:6s}  {name}"
            if msg:
                line += f"  ({msg})"
            f.write(line + "\n")

    # Print summary
    print(f"\n{'='*60}")
    print(f"Results: {len(results)} total, {passed} passed, {failed} failed")
    print(f"Log: {results_path}")

    # Post command
    if args.post_cmd and not args.dry_run:
        print(f"\n[POST] Running: {args.post_cmd}")
        subprocess.run(args.post_cmd, shell=True)

    return failed == 0
