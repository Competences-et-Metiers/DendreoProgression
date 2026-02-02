#!/usr/bin/env python3
"""
Test script to validate time aggregation logic with DidierChatierExample data
"""

import json
import sys
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

def analyze_participant_time_data(json_file_path):
    """Analyze participant time data from JSON file"""
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Group by participant email
        participant_data = {}
        
        for entry in data:
            participant = entry.get('participant', {})
            email = participant.get('email')
            name = f"{participant.get('prenom', '')} {participant.get('nom', '')}"
            
            if not email:
                continue
                
            if email not in participant_data:
                participant_data[email] = {
                    'name': name,
                    'entries': [],
                    'total_lms_tempspasse': 0,
                    'total_custom_time_spent': 0,
                    'total_aggregated': 0
                }
            
            # Extract time data
            lms_tempspasse = 0
            lms_tempspasse_str = entry.get('lms_tempspasse', '') or '0'
            try:
                lms_tempspasse = int(float(lms_tempspasse_str)) if lms_tempspasse_str else 0
            except (ValueError, TypeError):
                lms_tempspasse = 0
            
            # Extract custom_properties time
            custom_time = 0
            custom_properties = entry.get('custom_properties', {})
            if isinstance(custom_properties, dict):
                custom_time_str = custom_properties.get('total_time_spent', '0') or '0'
                try:
                    custom_time = int(float(custom_time_str)) if custom_time_str else 0
                except (ValueError, TypeError):
                    custom_time = 0
            
            # Use the larger value (as per our processing logic)
            entry_time = max(lms_tempspasse, custom_time)
            
            participant_data[email]['entries'].append({
                'id_lmp': entry.get('id_lmp'),
                'id_lam': entry.get('id_lam'),
                'lms_tempspasse': lms_tempspasse,
                'custom_time_spent': custom_time,
                'used_time': entry_time,
                'progression': entry.get('lms_progression', '0')
            })
            
            participant_data[email]['total_lms_tempspasse'] += lms_tempspasse
            participant_data[email]['total_custom_time_spent'] += custom_time
            participant_data[email]['total_aggregated'] += entry_time
        
        # Print results
        print("=== PARTICIPANT TIME AGGREGATION ANALYSIS ===\n")
        
        for email, data in participant_data.items():
            print(f"👤 {data['name']} ({email})")
            print(f"   📊 Total Entries: {len(data['entries'])}")
            print(f"   🕒 Total Aggregated Time: {data['total_aggregated']} seconds ({data['total_aggregated']/3600:.2f} hours)")
            print(f"   📈 LMS Tempspasse Sum: {data['total_lms_tempspasse']} seconds")
            print(f"   📈 Custom Time Sum: {data['total_custom_time_spent']} seconds")
            print()
            
            # Show individual entries
            for i, entry in enumerate(data['entries'], 1):
                print(f"      Entry {i}: LMP={entry['id_lmp']}, LAM={entry['id_lam']}")
                print(f"         lms_tempspasse: {entry['lms_tempspasse']}s")
                print(f"         custom_time: {entry['custom_time_spent']}s")
                print(f"         used_time: {entry['used_time']}s")
                print(f"         progression: {entry['progression']}%")
                print()
            
            print("-" * 60)
            print()
        
        return participant_data
        
    except Exception as e:
        print(f"Error analyzing data: {e}")
        return None

if __name__ == "__main__":
    json_file = "DidierChatierExample"
    if len(sys.argv) > 1:
        json_file = sys.argv[1]
    
    print(f"Analyzing time data from: {json_file}")
    analyze_participant_time_data(json_file)
