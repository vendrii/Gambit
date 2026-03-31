# %%
import os
import io
import time
import requests
import pandas as pd
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# --- CONFIGURATION ---
CLIENT_SECRET_FILE = 'client_secret.json'
FILE_ID = '### PUT YOUR SPREADSHEET FILE ID HERE ###'  # e.g. '1a2b3c4d5e6f7g8h9i0j'
SCOPES = [
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/spreadsheets.readonly'
]

def get_google_services():
    """Authenticates and returns services + a persistent session."""
    creds = None
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRET_FILE, SCOPES)
            creds = flow.run_local_server(port=0, access_type='offline', prompt='consent')
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
    
    drive_service = build('drive', 'v3', credentials=creds)
    sheets_service = build('sheets', 'v4', credentials=creds)
    
    # Create a persistent session for the heavy downloads
    session = requests.Session()
    session.headers.update({'Authorization': f'Bearer {creds.token}'})
    
    return drive_service, sheets_service, session

def list_history(drive_service):
    """Lists available revisions."""
    print(f"\n{'#'*10} SPREADSHEET REVISION HISTORY {'#'*10}")
    results = drive_service.revisions().list(fileId=FILE_ID).execute()
    revisions = results.get('revisions', [])
    for i, rev in enumerate(revisions):
        print(f"[{i:<3}] | {rev['id']:<15} | {rev['modifiedTime']}")
    return revisions

def get_tab_metadata(sheets_service):
    """Gets the names and GIDs of all tabs."""
    spreadsheet = sheets_service.spreadsheets().get(spreadsheetId=FILE_ID).execute()
    sheets = spreadsheet.get('sheets', [])
    return [{'name': s['properties']['title'], 'gid': s['properties']['sheetId']} for s in sheets]

def download_heavy_tab(session, revision_id, gid, tab_name):
    """Downloads a single tab with a massive timeout and retry logic."""
    url = f"https://docs.google.com/spreadsheets/d/{FILE_ID}/export?format=csv&revision={revision_id}&gid={gid}"
    
    # We will try 2 times per tab
    for attempt in range(1, 3):
        try:
            print(f"   ⏳ Attempt {attempt} for '{tab_name}' (Timeout: 10 mins)...")
            # 600 seconds = 10 minutes for Google to calculate the revision
            response = session.get(url, timeout=600)
            
            if response.status_code == 200:
                return pd.read_csv(io.BytesIO(response.content))
            elif response.status_code == 429:
                print("   ⚠️ Rate limit hit. Waiting 30s...")
                time.sleep(30)
            else:
                print(f"   ❌ Server returned status: {response.status_code}")
                
        except requests.exceptions.Timeout:
            print(f"   🕒 Timeout on attempt {attempt}. Google is struggling with this tab.")
            if attempt == 1:
                print("   🔄 Retrying once more to see if the server 'warmed up'...")
                time.sleep(5)
        except Exception as e:
            print(f"   ❌ Connection Error: {e}")
            break
            
    return None

if __name__ == "__main__":
    try:
        # 1. Auth
        drive_service, sheets_service, session = get_google_services()
        
        # 2. Get History
        history = list_history(drive_service)
        
        # 3. Selection
        choice = input("\nEnter Index [#] or Revision ID (e.g. 11092): ").strip()
        selected_rev_id = None
        if choice.isdigit() and int(choice) < len(history):
            selected_rev_id = history[int(choice)]['id']
        else:
            selected_rev_id = choice

        if selected_rev_id:
            # 4. Get Metadata
            tabs = get_tab_metadata(sheets_service)
            print(f"\n🚀 Found {len(tabs)} tabs. Starting Heavy-Duty Export...")

            # 5. Process Tabs
            for tab in tabs:
                name = tab['name']
                gid = tab['gid']
                
                df_temp = download_heavy_tab(session, selected_rev_id, gid, name)
                
                if df_temp is not None:
                    # Create variable names like df_raw, df_pivot
                    clean_name = name.lower().replace(' ', '_').replace('-', '_')
                    var_name = f"df_{clean_name}"
                    globals()[var_name] = df_temp
                    print(f"   ✅ Variable Created: {var_name} ({len(df_temp)} rows)")
                else:
                    print(f"   ❌ Could not recover tab: {name}")

            print("\n🎉 Process complete. Check your variables (df_raw, etc.)")
        else:
            print("❌ Invalid selection.")

    except Exception as e:
        print(f"\n❌ CRITICAL ERROR: {e}")
# %%
