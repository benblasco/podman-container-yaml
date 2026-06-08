# Unifi backups

The native Unifi backup functionality is in use, carrying out automatic backups weekly. These are local to the instance, and therefore not being synchronised off site.

You can find the configuration under Settings -> System -> Backups

## Unifi Wifi Optimisation

Optimising hand off between APs

Optimizing Wi-Fi handoff (roaming) between UniFi Access Points (APs) relies on controlling client device decisions rather than forcing the APs to pull a device. To resolve "sticky clients" that refuse to switch, properly configure 802.11 protocols and radio power levels.To configure a seamless handover:

1. Enable Roaming Standards: Go to Settings > WiFi and select your wireless network. Ensure Advanced is set to Manual.
	- Enable BSS Transition (802.11v): This allows APs to send nearby AP signal information to your clients, allowing for smarter roaming decisions.
	- Enable Fast Roaming (802.11r): Speeds up the authentication handshake when moving between APs. (Note: If you have legacy smart home/IoT devices, keep this disabled as it may cause them connectivity issues).
  
# Band steering to prefer 5GHz over 2.4 GHz

This feature encourages compatible devices to prefer the 5 GHz band over the 2.4 GHz band. \[[1](https://help.ui.com/hc/en-us/articles/32065480092951-UniFi-WiFi-SSID-and-AP-Settings-Overview)\]

1.  Open your **UniFi Network Application** and go to **Settings** > **WiFi**.
2.  Click on the **Wireless Network (SSID)** you want to edit.
3.  Expand the **Advanced** or **WiFi** section (depending on your controller version).
4.  Look for the **Band Steering** toggle and turn it **ON**.
5.  Click **Apply Changes**. \[[1](https://www.youtube.com/watch?v=b0i_m5Nq7sM), [2](https://help.ui.com/hc/en-us/articles/32065480092951-UniFi-WiFi-SSID-and-AP-Settings-Overview)\]

## Setting 5GHz network to 80MHz channel width and optimise settings

Thanks to Google in AI mode

source: https://www.reddit.com/r/Ubiquiti/comments/196w8tk/wifi_is_slow_but_wired_connection_is_fast_not/

Given your 500 Mbps internet speed and 2-AP setup, **80MHz is the perfect choice** for your 5GHz radios. It allows a single wireless client to maximize your full 500 Mbps download speed under good signal conditions. \[[1](https://www.reddit.com/r/Ubiquiti/comments/196w8tk/wifi_is_slow_but_wired_connection_is_fast_not/), [2](https://www.reddit.com/r/HomeNetworking/comments/1k31d52/500mbit_with_access_point/)\]

Because you have two Access Points (APs), the key to keeping the network stable is ensuring they do not use the same channels. \[[1](https://community.ui.com/questions/AP-same-SSID-as-the-router/502dfcbd-7930-446d-9e8a-d8972c7a6455)\]

### Recommended 5GHz Settings (80MHz) \[[1](https://www.reddit.com/r/Ubiquiti/comments/196w8tk/wifi_is_slow_but_wired_connection_is_fast_not/)\]

To prevent your APs from competing with each other, manually assign them to opposite ends of the 5GHz spectrum: \[[1](https://www.reddit.com/r/wifi/comments/1libjhw/two_access_points_in_the_same_room/)\]

- **Flex HD:** Set channel width to **HE80/VHT80** and manually select **Channel 36** (uses channels 36-48).
- **U6-Lite:** Set channel width to **HE80** and manually select **Channel 149** (uses channels 149-161). \[[1](https://community.ui.com/questions/d7360062-7a3f-4d5c-847a-86aca052f696)\]

*Note: If your local region restricts channel 149, use channel 52 (DFS) instead, provided you do not live near an airport or radar station.*

### Recommended 2.4GHz Settings (20MHz) \[[1](https://community.ui.com/questions/UniFi-AP-Enterprise-WiFi-System-and-Comcast-router-modem/b0e36b44-8c72-4694-b575-df5a1fbc443c)\]

To avoid severe overlapping interference, never use 40MHz on the 2.4GHz band.

- **Flex HD:** Set channel width to **HT20** and select **Channel 1**.
- **U6-Lite:** Set channel width to **HT20** and select **Channel 11**. \[[1](https://community.ui.com/questions/Poor-speed-between-BT-Hub-and-UniFi-Access-Point/ee98c9de-ec71-47c9-91d8-ee3ced38037e), [2](https://www.reddit.com/r/Ubiquiti/comments/136ukwq/unifi_u6_pro_vs_u6_lite_160mhz_option/), [3](https://www.reddit.com/r/Ubiquiti/comments/1t0g5g6/u6lr_24ghz_horrible_speeds/)\]

## Setting transmit power appropriately

Again thanks to Google

Fix the Power Imbalance (Most Important)

Devices stick to distant APs because the APs are blasting too much power. 2.4GHz signals travel much further than 5GHz signals, causing devices to stay glued to a slow 2.4GHz connection.

Change the Transmit (Tx) Power from "Auto" to manual values:

- **5GHz Band (Both APs):** Set to **Medium**.
- **2.4GHz Band (Both APs):** Set to **Low**.

*Why this works:* This shrinks the artificial coverage bubble. When you walk away from one AP, your phone will actually notice the signal drop and quickly look for the closer AP.
