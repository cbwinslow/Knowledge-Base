#!/usr/bin/env python3
import http.server, socketserver, json, os
PORT=9108; EVE=os.environ.get('CBW_EVE','/var/log/suricata/eve.json')
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path!='/metrics': self.send_error(404); return
        counts={'total':0,'alert':0,'alert_high':0}
        try:
            with open(EVE,'rb') as f:
                for ln in f.readlines()[-2000:]:
                    try:
                        j=json.loads(ln.decode('utf-8','ignore'))
                        counts['total']+=1
                        if j.get('event_type')=='alert':
                            counts['alert']+=1
                            if int(j.get('alert',{}).get('severity',0))>=2: counts['alert_high']+=1
                    except Exception: pass
        except Exception: pass
        out=(f"cbw_eve_total {counts['total']}
"
             f"cbw_eve_alert {counts['alert']}
"
             f"cbw_eve_alert_high {counts['alert_high']}
")
        self.send_response(200); self.send_header('Content-Type','text/plain; version=0.0.4'); self.end_headers(); self.wfile.write(out.encode())
with socketserver.TCPServer(('',PORT), H) as httpd: httpd.serve_forever()
