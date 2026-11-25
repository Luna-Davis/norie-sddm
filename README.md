# Norie SDDM

This is a simple SDDM designed to be used with Norie shell, my custom shell.

## Installation

Do the following:

```bash
git clone https://github.com/Luna-Davis/norie-sddm.git
sudo mkdir -p /usr/share/sddm/themes/norie
sudo cp -r norie-sddm/. /usr/share/sddm/themes/norie/

# SDDM theme metadata filename
sudo mv /usr/share/sddm/themes/norie/Metadata.desktop \
        /usr/share/sddm/themes/norie/metadata.desktop

# Configure SDDM
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=norie\n' | sudo tee /etc/sddm.conf.d/theme.conf

echo "DONE!"
```

or do this instead:

```bash
git clone https://github.com/Luna-Davis/norie-sddm.git && \
sudo mkdir -p /usr/share/sddm/themes/norie && \
sudo cp -r norie-sddm/. /usr/share/sddm/themes/norie/ && \
sudo mv /usr/share/sddm/themes/norie/Metadata.desktop /usr/share/sddm/themes/norie/metadata.desktop && \
sudo mkdir -p /etc/sddm.conf.d && \
printf '[Theme]\nCurrent=norie\n' | sudo tee /etc/sddm.conf.d/theme.conf && \
echo "DONE!"
```

---

Enjoy!
