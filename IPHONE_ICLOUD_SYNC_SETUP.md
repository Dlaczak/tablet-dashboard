# iPhone/iCloud Sync Setup Guide

This guide covers syncing your iPhone Reminders lists and Sleep Schedule alarm with Home Assistant.

## Overview

| Feature | iCloud Source | HA Entity | Sync Method |
|---------|---------------|-----------|-------------|
| Shopping List | Reminders "Shopping" list | `todo.shopping_list` | Webhook |
| Chores List | Reminders "Chores" list | `todo.chores` | Webhook |
| Wake Alarm | Health Sleep Schedule | `input_datetime.iphone_wake_alarm` | Webhook |

---

## Prerequisites

### 1. Create Required Helpers in Home Assistant

Go to **Settings > Devices & Services > Helpers** and create:

1. **Shopping List** (if not using built-in)
   - Type: To-do list
   - Name: `Shopping List`
   - Entity ID: `todo.shopping_list`

2. **Chores List**
   - Type: To-do list
   - Name: `Chores`
   - Entity ID: `todo.chores`

3. **iPhone Wake Alarm**
   - Type: Date and/or time
   - Name: `iPhone Wake Alarm`
   - Entity ID: `input_datetime.iphone_wake_alarm`
   - Options: Check "Date" and "Time"

### 2. Add Automations to Home Assistant

Copy the contents of `icloud_sync_automations.yaml` into your Home Assistant:

**Option A - Packages (Recommended):**
1. Create folder: `config/packages/`
2. Add to `configuration.yaml`:
   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```
3. Save `icloud_sync_automations.yaml` to `config/packages/`

**Option B - Manual:**
1. Go to **Settings > Automations & Scenes**
2. Create each automation manually from the YAML
3. Go to **Settings > Automations & Scenes > Scripts**
4. Create each script manually from the YAML

### 3. Get Your Webhook URLs

Your webhook URLs will be:
- Shopping List: `https://homeassistant.davidlaczak.com/api/webhook/shopping_list_sync`
- Chores List: `https://homeassistant.davidlaczak.com/api/webhook/chores_list_sync`
- Wake Alarm: `https://homeassistant.davidlaczak.com/api/webhook/wake_alarm_sync`


---

## Part 1: Shopping List Sync

### Create the iPhone Reminders List

1. Open **Reminders** app on iPhone
2. Tap **Add List** (bottom left)
3. Name it **Shopping** (or whatever you prefer)
4. Optional: Share with family via iCloud

### Create the iPhone Shortcut

1. Open **Shortcuts** app
2. Tap **+** to create new shortcut
3. Name it: **Sync Shopping List to HA**
4. Add these actions:

```
1. Find Reminders Where
   - List is "Shopping"
   - Is Completed is "No"

2. Repeat with Each Item in "Reminders"
   - Get Variable: Repeat Item
   - Get "Name" from "Repeat Item"
   - Add to Variable: "items"
   End Repeat

3. Dictionary
   - Add "action" : "sync"
   - Add "items" : items

4. Get Contents of URL
   - URL: https://homeassistant.davidlaczak.com/api/webhook/shopping_list_sync
   - Method: POST
   - Request Body: JSON
   - Body: Dictionary (from step 3)
```

### Alternative: Quick Add Single Item

Create a second shortcut for quickly adding items:

```
1. Ask for Input
   - Prompt: "What do you need?"
   - Input Type: Text

2. Dictionary
   - Add "action" : "add"
   - Add "item" : Provided Input

3. Get Contents of URL
   - URL: https://homeassistant.davidlaczak.com/api/webhook/shopping_list_sync
   - Method: POST
   - Request Body: JSON
```

### Automation Options

- **Manual**: Run shortcut whenever you want to sync
- **Siri**: "Hey Siri, Sync Shopping List to HA"
- **Automatic**: Create Shortcuts Automation triggered by:
  - Leaving home (location)
  - Time of day
  - Opening a specific app

---

## Part 2: Chores List Sync

### Create the iPhone Reminders List

1. Open **Reminders** app
2. Create a new list called **Chores**
3. Add your recurring chores
4. Optional: Share with family via iCloud

### Create the iPhone Shortcut

Same process as Shopping List, but:
- Use "Chores" list instead of "Shopping"
- Use webhook URL: `https://YOUR_HA_URL/api/webhook/chores_list_sync`

**Shortcut: Sync Chores List to HA**

```
1. Find Reminders Where
   - List is "Chores"
   - Is Completed is "No"

2. Repeat with Each Item in "Reminders"
   - Get Variable: Repeat Item
   - Get "Name" from "Repeat Item"
   - Add to Variable: "items"
   End Repeat

3. Dictionary
   - Add "action" : "sync"
   - Add "items" : items

4. Get Contents of URL
   - URL: https://homeassistant.davidlaczak.com/api/webhook/chores_list_sync
   - Method: POST
   - Request Body: JSON
```

---

## Part 3: Wake Alarm Sync (iOS 17+)

This syncs your iPhone Sleep Schedule alarm time to Home Assistant so you can automate lights, coffee makers, etc. based on when you'll wake up.

### Requirements

- iOS 17 or later
- Sleep Schedule configured in Health app

### Create the iPhone Shortcut

**Shortcut: Sync Wake Alarm to HA**

```
1. Get Upcoming Events
   - Calendar: "Sleep"
   - (This gets your Sleep Schedule from Health)

2. Get "End Date" from "Calendar Events"
   - (End Date = Wake Time)

3. Format Date
   - Format: Custom
   - Format String: yyyy-MM-dd'T'HH:mm:ss
   - (This creates ISO8601 format)

4. Dictionary
   - Add "wake_time" : Formatted Date

5. Get Contents of URL
   - URL: https://homeassistant.davidlaczak.com/api/webhook/wake_alarm_sync
   - Method: POST
   - Request Body: JSON
```

**Alternative Method (if above doesn't work):**

Some users report better results with:

```
1. Get Health Sample
   - Type: Sleep Analysis
   - Group By: None
   - Sort By: Start Date (Latest First)
   - Limit: 1

2. Get "End Date" from "Health Sample"

3. Format Date...
   (continue as above)
```

### Automation: Auto-Sync at Bedtime

Create a Shortcuts Automation to automatically sync when you go to bed:

1. Open **Shortcuts** app
2. Go to **Automation** tab
3. Tap **+** > **Create Personal Automation**
4. Choose: **Sleep** > **Wind Down Begins**
5. Add action: **Run Shortcut** > "Sync Wake Alarm to HA"
6. Turn OFF "Ask Before Running"

Now every night when Wind Down starts, your wake time syncs to HA automatically.

---

## Part 4: Using Wake Time in Home Assistant

### Example Automation: Morning Lights

```yaml
automation:
  - alias: "Wake Up Lights"
    trigger:
      - platform: template
        value_template: >
          {{ now().strftime('%H:%M') ==
             (states('input_datetime.iphone_wake_alarm') | as_datetime - timedelta(minutes=15)).strftime('%H:%M') }}
    action:
      - service: light.turn_on
        target:
          entity_id: light.bedroom
        data:
          brightness_pct: 10
          transition: 900  # 15 min fade
```

### Example: Display on Dashboard

```yaml
- type: custom:bubble-card
  card_type: button
  button_type: state
  entity: input_datetime.iphone_wake_alarm
  name: Tomorrow's Alarm
  icon: mdi:alarm
  show_state: true
```

---

## Troubleshooting

### Webhook Not Working

1. **Check URL**: Make sure you're using your external HA URL
2. **Check HTTPS**: Webhooks require HTTPS for external access
3. **Test manually**: Use curl or Postman to test the webhook:
   ```bash
   curl -X POST https://YOUR_HA_URL/api/webhook/shopping_list_sync \
     -H "Content-Type: application/json" \
     -d '{"action":"add","item":"Test item"}'
   ```

### Sleep Calendar Not Found

- Make sure Sleep Schedule is enabled in Health > Sleep
- Check that you have a Sleep Schedule configured (not just Bedtime)
- Try restarting your iPhone

### Items Not Syncing

- Check Home Assistant logs for webhook errors
- Verify the helper entities exist
- Make sure the automation is enabled

### Automation Not Running

- Check that "Ask Before Running" is OFF
- Verify Sleep Focus is configured in Settings > Focus

---

## Webhook Reference

### Shopping/Chores List Payloads

**Sync entire list:**
```json
{
  "action": "sync",
  "items": ["Milk", "Bread", "Eggs"]
}
```

**Add single item:**
```json
{
  "action": "add",
  "item": "Bananas"
}
```

**Clear completed and sync:**
```json
{
  "action": "clear_and_sync",
  "items": ["Milk", "Bread"]
}
```

### Wake Alarm Payload

```json
{
  "wake_time": "2024-01-15T06:30:00"
}
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `icloud_sync_automations.yaml` | All HA automations and scripts for syncing |
| `home.yaml` | Dashboard with sync buttons in popups |

---

## Credits

Wake alarm sync method based on: https://community.home-assistant.io/t/sync-ios-17-sleep-alarm-to-ha/622297
