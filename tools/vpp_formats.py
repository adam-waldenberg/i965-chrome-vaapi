import ctypes, os, struct

va = ctypes.CDLL("libva.so.2")
vadrm = ctypes.CDLL("libva-drm.so.2")

fd = os.open("/dev/dri/renderD128", os.O_RDWR)
vadrm.vaGetDisplayDRM.restype = ctypes.c_void_p
dpy = vadrm.vaGetDisplayDRM(fd)
maj, mino = ctypes.c_int(), ctypes.c_int()
assert va.vaInitialize(ctypes.c_void_p(dpy), ctypes.byref(maj), ctypes.byref(mino)) == 0
va.vaQueryVendorString.restype = ctypes.c_char_p
print("vendor:", va.vaQueryVendorString(ctypes.c_void_p(dpy)).decode())

VAProfileNone = -1
VAEntrypointVideoProc = 10
cfg = ctypes.c_uint()
r = va.vaCreateConfig(ctypes.c_void_p(dpy), VAProfileNone, VAEntrypointVideoProc,
                      None, 0, ctypes.byref(cfg))
print("vaCreateConfig(VideoProc) ->", r)


class GenericValue(ctypes.Structure):
    _fields_ = [("type", ctypes.c_int), ("value", ctypes.c_uint64)]


class SurfaceAttrib(ctypes.Structure):
    _fields_ = [("type", ctypes.c_int), ("flags", ctypes.c_uint), ("value", GenericValue)]


n = ctypes.c_uint(0)
va.vaQuerySurfaceAttributes(ctypes.c_void_p(dpy), cfg, None, ctypes.byref(n))
arr = (SurfaceAttrib * n.value)()
va.vaQuerySurfaceAttributes(ctypes.c_void_p(dpy), cfg, arr, ctypes.byref(n))
VASurfaceAttribPixelFormat = 1
fourccs = []
for a in arr[: n.value]:
    if a.type == VASurfaceAttribPixelFormat:
        fourccs.append(struct.pack("<I", a.value.value & 0xFFFFFFFF).decode("latin1"))
print("VPP pixel formats:", fourccs)
