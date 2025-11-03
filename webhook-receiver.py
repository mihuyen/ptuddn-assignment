#!/usr/bin/env python3
"""
HTTP Webhook Receiver - Nhận alert từ AlertManager
Lưu alert vào file và in ra console
"""
from flask import Flask, request, jsonify
from datetime import datetime
import json

app = Flask(__name__)

@app.route('/alert', methods=['POST'])
def receive_alert():
    """Nhận alert từ AlertManager"""
    data = request.get_json()
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    if data and 'alerts' in data:
        for alert in data['alerts']:
            print(f"\n{'='*60}")
            print(f"🚨 ALERT RECEIVED: {timestamp}")
            print(f"{'='*60}")
            print(f"Status: {alert.get('status', 'unknown')}")
            print(f"Alert Name: {alert.get('labels', {}).get('alertname', 'unknown')}")
            print(f"Severity: {alert.get('labels', {}).get('severity', 'unknown')}")
            print(f"Pod: {alert.get('labels', {}).get('pod', 'unknown')}")
            print(f"Summary: {alert.get('annotations', {}).get('summary', 'N/A')}")
            print(f"Description: {alert.get('annotations', {}).get('description', 'N/A')}")
            print(f"{'='*60}\n")
            
            # Lưu vào file
            with open('/tmp/alerts.log', 'a') as f:
                f.write(json.dumps({
                    'timestamp': timestamp,
                    'alert': alert
                }) + '\n')
    
    return jsonify({'status': 'received'}), 200

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    print("🚀 Webhook Receiver starting on port 5000...")
    app.run(host='0.0.0.0', port=5000, debug=False)
