import importlib, sys, platform
print("python", sys.version.replace("\n", " "), platform.machine())
mods = ["numpy", "pandas", "cv2", "mediapipe", "onnxruntime", "psutil", "openpyxl", "scipy", "sklearn", "matplotlib", "PIL", "docx"]
for m in mods:
    try:
        mod = importlib.import_module(m)
        print(f"OK   {m} {getattr(mod, '__version__', '?')}")
    except Exception as e:
        print(f"FAIL {m}: {type(e).__name__}: {e}")
try:
    import onnxruntime as ort
    print("ORT providers:", ort.get_available_providers())
except Exception:
    pass
