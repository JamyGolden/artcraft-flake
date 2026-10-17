# The ArtCraft apps (https://getartcraft.com/apps), keyed by package name. The package name is also
# the binary name and the release asset prefix.
#
# The pinned release of each app lives in releases.json, which ./scripts/update.sh regenerates.
#
#   displayName   the macOS bundle and executable name (<displayName>.app/Contents/MacOS/<displayName>)
#   repo          github:storytold/<repo>
#   cli           whether the app ships a headless `<name>-cli` alongside the GUI
#   mime          whether the app installs a shared-mime-info package
#   buildInputs   extra native libraries the app links against (beyond the shared GUI libs)
#   runtimeLibs   extra native libraries the app dlopens, which go on its RPATH
#   driverLibs    whether the app dlopens libraries that come with the graphics driver (CUDA, NVDEC),
#                 so it also looks in /run/opengl-driver/lib, where NixOS puts them
{
  photocraft = {
    displayName = "PhotoCraft";
    description = "Open-source, native, Photoshop-comparable image editor";
  };
  vectorcraft = {
    displayName = "VectorCraft";
    description = "Open-source vector illustration";
  };
  filmcraft = {
    displayName = "FilmCraft";
    description = "Open-source nonlinear video editor";
    buildInputs = pkgs: [pkgs.alsa-lib];
    # VA-API for hardware video decoding.
    runtimeLibs = pkgs: [pkgs.libva];
    driverLibs = true;
  };
  lightcraft = {
    displayName = "LightCraft";
    description = "Open-source photo library and raw developer";
  };
  pdfcraft = {
    displayName = "PdfCraft";
    description = "Open-source PDF workbench: read, organize, combine, split and secure";
  };
  effectcraft = {
    displayName = "EffectCraft";
    description = "Open-source motion graphics and visual effects";
    buildInputs = pkgs: [pkgs.alsa-lib];
  };
  designcraft = {
    displayName = "DesignCraft";
    description = "Open-source page layout and publishing";
  };
  figcraft = {
    displayName = "FigCraft";
    description = "Open-source interface design and prototyping";
  };
  wordcraft = {
    displayName = "WordCraft";
    description = "Open-source word processor";
  };
  soundcraft = {
    displayName = "SoundCraft";
    description = "Open-source audio recording, editing and mixing";
    buildInputs = pkgs: [pkgs.alsa-lib];
  };
  deckcraft = {
    displayName = "DeckCraft";
    description = "Open-source slide presentations";
    buildInputs = pkgs: [pkgs.alsa-lib];
  };
  cadcraft = {
    displayName = "CADCraft";
    description = "Open-source computer-aided design and drafting";
  };
  gridcraft = {
    displayName = "GridCraft";
    description = "Open-source spreadsheets and data analysis";
  };
  artcraft-launcher = {
    displayName = "ArtCraft Launcher";
    description = "Launcher for the ArtCraft apps";
    repo = "craft-launcher";
    cli = false;
    mime = false;
  };
}
