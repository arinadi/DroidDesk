#!/bin/bash
# ═══════════════════════════════════════════
#  arinanoX Dark Mobile Theme
#  Blackbird GTK + xfwm4 + Adwaita icons + 64px panel
# ═══════════════════════════════════════════

CONF_DIR="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$CONF_DIR"

echo ">>> Applying arinanoX Dark Mobile Theme..."

# ── xsettings: Orchis-Dark, elementary-xfce-hidpi, DPI 144 (1.5x) ──
cat > "$CONF_DIR/xsettings.xml" << 'XEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Orchis-Dark"/>
    <property name="IconThemeName" type="string" value="elementary-xfce-hidpi"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="int" value="96"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Sans 12"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorThemeSize" type="int" value="24"/>
  </property>
  <property name="Xfce" type="empty">
    <property name="LastCustomDPI" type="int" value="96"/>
    <property name="WindowScalingFactor" type="int" value="2"/>
  </property>
</channel>
XEOF

# ── xfwm4: Orchis-Dark-xhdpi, center, no compositing ──
cat > "$CONF_DIR/xfwm4.xml" << 'WMEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="theme" type="string" value="Orchis-Dark-xhdpi"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="borderless_maximize" type="bool" value="true"/>
    <property name="title_font" type="string" value="Sans Bold 11"/>
    <property name="workspace_count" type="int" value="1"/>
  </property>
</channel>
WMEOF

# ── Panel: 64px dark, borderless, Whisker + Tasklist ──
cat > "$CONF_DIR/xfce4-panel.xml" << 'PEOF'
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="64"/>
      <property name="background-style" type="uint" value="2"/>
      <property name="background-alpha" type="uint" value="85"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu">
      <property name="show-menu-icons" type="bool" value="true"/>
      <property name="show-generic-names" type="bool" value="false"/>
      <property name="recent-items-max" type="int" value="5"/>
      <property name="view-mode" type="uint" value="1"/>
      <property name="open-at-mouse" type="bool" value="false"/>
    </property>
    <property name="plugin-2" type="string" value="tasklist">
      <property name="show-labels" type="bool" value="false"/>
      <property name="grouping" type="uint" value="1"/>
      <property name="icon-size" type="uint" value="48"/>
    </property>
  </property>
</channel>
PEOF

# ── Desktop: almost-black, no icons ──
cat > "$CONF_DIR/xfce4-desktop.xml" << 'DEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-style" type="int" value="0"/>
        <property name="color-style" type="int" value="0"/>
        <property name="rgba1" type="array">
          <value type="double" value="0.05"/>
          <value type="double" value="0.05"/>
          <value type="double" value="0.05"/>
          <value type="double" value="1.0"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="primary" type="bool" value="false"/>
  </property>
</channel>
DEOF

echo ""
echo "╔═══════════════════════════════════╗"
echo "║  🎨 Orchis Material + Elementary   ║"
echo "╠═══════════════════════════════════╣"
echo "║  GTK:   Orchis-Dark (Material)     ║"
echo "║  Icons: elementary-xfce-hidpi      ║"
echo "║  WM:    Orchis-Dark-xhdpi          ║"
echo "║  Panel: 64px borderless, 2 plugins  ║"
echo "║  DPI:   96 (Scale 2x)   ║"
echo "║  Font:  Sans 12                    ║"
echo "║  Cursor: 24px (2x → 48px)                      ║"
echo "╠═══════════════════════════════════╣"
echo "║  Restart XFCE to apply            ║"
echo "╚═══════════════════════════════════╝"
