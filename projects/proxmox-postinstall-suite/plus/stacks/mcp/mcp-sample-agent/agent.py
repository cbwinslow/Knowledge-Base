import os,time,requests
hub=os.getenv('MCP_HUB_URL','http://mcp-hub:8787')
name='sample-agent'
try:
 r=requests.post(f"{hub}/register",json={'name':name,'url':'http://sample'})
 print('Registered:',r.json())
except Exception as e:
 print('Register failed:',e)
while True:
 print('Heartbeat from',name); time.sleep(30)
