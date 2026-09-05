--╔══════════════════════════════════════╗--
--║   	  Environmental Variables        ║--
--╚══════════════════════════════════════╝--


-- Environmental variables (for reference https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/)
-- if you use UWSM, define your variables in ~/.config/uwsm/env
-- if you don't use UWSM, define your variables here (e.g. hl.env("QT_QPA_PLATFORM", "wayland"))

-- if you have an NVIDIA GPU uncomment the following lines:

hl.env("GBM_BACKEND", "nvidia-drm") -- force GBM as a backend
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- força uso da lib GLX da NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia") -- Hardware acceleration on NVIDIA GPUs
hl.env("__GL_GSYNC_ALLOWED", "1") -- Controls if G-Sync capable monitors should use Variable Refresh Rate (VRR)


hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- forces every Qt6 application to use qt6ct for theming



-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

--hl.env("AQ_DRM_DEVICES","/dev/dri/card1:/dev/dri/card0")
--hl.env ("","")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- hl.env("__NV_PRIME_RENDER_OFFLOAD_PROVIDER","NVIDIA-G0")
-- hl.env("__VK_LAYER_NV_optimus","NVIDIA_only")
-- hl.env("VK_ICD_FILENAMES","/usr/share/vulkan/icd.d/nvidia_icd.json")
-- hl.env("__NV_PRIME_RENDER_OFFLOAD","1")



