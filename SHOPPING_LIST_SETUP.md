# Shopping List iCloud Sync Setup

This guide explains how to sync your iPhone Reminders shopping list with Home Assistant.

---

## Overview

- **HA Side**: Uses native `todo.shopping_list` entity displayed in dashboard
- **iPhone Side**: Apple Shortcuts sync with iCloud Reminders
- **Sync Method**: Periodic via Shortcuts Automation or manual button press

---

## Step 1: Home Assistant Setup

### 1.1 Create the Todo List Entity

The built-in shopping list should already exist. If not:

1. Go to **Settings > Devices & Services > Helpers**
2. Add **To-do list** helper
3. Name it "Shopping List" (entity: `todo.shopping_list`)

### 1.2 Add Webhook Automation

Copy the automation from `shopping_list_automations.yaml` to your HA:

**Option A: Via UI**
1. Go to **Settings > Automations & Scenes**
2. Create new automation
3. Add **Webhook** trigger with ID: `shopping_list_sync`
4. Add the actions from the template file

**Option B: Via YAML**
1. Copy the automation section to your `automations.yaml`
2. Reload automations

### 1.3 Add the Sync Script

1. Go to **Settings > Automations & Scenes > Scripts**
2. Create new script named "Sync Shopping List"
3. Use entity ID: `script.sync_shopping_list`
4. Copy actions from `shopping_list_automations.yaml`

### 1.4 Update Mobile App Name

In `shopping_list_automations.yaml`, replace `mobile_app_YOUR_IPHONE` with your actual device name (e.g., `mobile_app_davids_iphone`).

---

## Step 2: iPhone Shortcut - Pull from iCloud

This Shortcut reads your iCloud Reminders and sends them to Home Assistant.

### Create the Shortcut

1. Open **Shortcuts** app on iPhone
2. Tap **+** to create new Shortcut
3. Name it: **"Sync Shopping List to HA"**

### Add Actions

```
1. Find Reminders Where
   - List is "Shopping List"
   - Is Not Completed is true

2. Repeat with Each (Reminders)
   - Get Variable: Repeat Item
   - Get Name of Reminder
   - Add to Variable: ItemNames

3. Set Variable "ItemList" to ItemNames

4. Get Contents of URL
   - URL: https://YOUR_HA_URL/api/webhook/shopping_list_sync
   - Method: POST
   - Headers: Content-Type: application/json
   - Request Body: JSON
     {
       "action": "sync",
       "items": [ItemList]
     }

5. Show Notification
   - "Shopping list synced to Home Assistant"
```

### Alternative: Simpler Version

```
1. Find Reminders Where
   - List is "Shopping List"
   - Is Not Completed

2. Combine Text (Reminders)
   - Custom separator: ","

3. Text
   {"action":"sync","items":["[Combined Text split by comma]"]}

4. Get Contents of URL
   - URL: https://YOUR_HA_URL/api/webhook/shopping_list_sync
   - Method: POST
   - Request Body: File (the Text from step 3)
```

---

## Step 3: iPhone Shortcut - Push to iCloud

This Shortcut receives items from HA and adds them to iCloud Reminders.

### Create the Shortcut

1. Open **Shortcuts** app
2. Create new Shortcut
3. Name it: **"Update iCloud Shopping List"**

### Add Actions

```
1. Receive [Text] input from Share Sheet/Notification

2. Get Dictionary from Input

3. Repeat with Each (Dictionary Items)
   - Add New Reminder
     - Title: [Current Item]
     - List: Shopping List
     - Remind Me: (leave blank)

4. Show Notification
   - "Added items to Shopping List"
```

---

## Step 4: Automate the Sync

### Option A: Time-Based Automation

1. Open **Shortcuts** app
2. Go to **Automation** tab
3. Tap **+** > **Create Personal Automation**
4. Choose **Time of Day**
5. Set times (e.g., 8:00 AM and 6:00 PM)
6. Action: **Run Shortcut** > "Sync Shopping List to HA"
7. Disable "Ask Before Running"

### Option B: Location-Based

1. Create automation triggered when arriving/leaving home
2. Run the sync Shortcut

### Option C: App-Based

1. Create automation for "When Home Assistant app opens"
2. Run the sync Shortcut

---

## Step 5: Testing

### Test Webhook

Use curl to test your webhook:

```bash
curl -X POST https://YOUR_HA_URL/api/webhook/shopping_list_sync \
  -H "Content-Type: application/json" \
  -d '{"action":"sync","items":["Milk","Bread","Eggs"]}'
```

### Test from iPhone

1. Add item to Reminders shopping list
2. Run "Sync Shopping List to HA" Shortcut
3. Check HA dashboard - item should appear

---

## Webhook Reference

**URL**: `https://YOUR_HA_URL/api/webhook/shopping_list_sync`

**Method**: POST

**Actions**:

| Action | Description | Body |
|--------|-------------|------|
| `sync` | Add items to HA list | `{"action":"sync","items":["item1","item2"]}` |
| `add` | Add single item | `{"action":"add","item":"Milk"}` |
| `clear_and_sync` | Clear HA list, then add items | `{"action":"clear_and_sync","items":[...]}` |

---

## Troubleshooting

### Items not appearing in HA
- Check webhook URL is correct
- Verify `todo.shopping_list` entity exists
- Check HA logs for webhook errors

### Shortcut not running
- Ensure Shortcuts has permission to access Reminders
- Test URL access separately with Safari

### Sync not triggering automatically
- Check Shortcuts automation is enabled
- Disable "Ask Before Running" on automation

---

## Notes

- Both you and your wife can add items to the shared iCloud Reminders list
- Sync pulls from iCloud to HA - items added in HA stay local until pushed
- For true bidirectional sync, run both shortcuts periodically
- Consider adding a "completed" sync to mark items done in iCloud when checked off in HA
