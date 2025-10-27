#!/usr/bin/env python3
"""
System Monitoring and Alerting Script

This script demonstrates:
- System resource monitoring (CPU, memory, disk)
- Service health checks
- Database monitoring
- Alert notifications
- Logging and reporting
"""

import os
import sys
import time
import json
import psutil
import smtplib
import requests
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from loguru import logger


@dataclass
class MonitoringThresholds:
    """Monitoring thresholds configuration"""
    cpu_warning: float = 70.0
    cpu_critical: float = 90.0
    memory_warning: float = 75.0
    memory_critical: float = 90.0
    disk_warning: float = 80.0
    disk_critical: float = 95.0
    response_time_warning: float = 2.0
    response_time_critical: float = 5.0


@dataclass
class Alert:
    """Alert data structure"""
    timestamp: str
    level: str  # info, warning, critical
    category: str
    message: str
    value: Optional[float] = None
    threshold: Optional[float] = None


class SystemMonitor:
    """Monitor system resources"""
    
    def __init__(self, thresholds: MonitoringThresholds):
        self.thresholds = thresholds
        self.alerts: List[Alert] = []
    
    def check_cpu(self) -> Dict:
        """Monitor CPU usage"""
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        cpu_per_core = psutil.cpu_percent(interval=1, percpu=True)
        
        # Check thresholds
        level = "info"
        if cpu_percent >= self.thresholds.cpu_critical:
            level = "critical"
            self.add_alert(
                level="critical",
                category="CPU",
                message=f"CPU usage critical: {cpu_percent}%",
                value=cpu_percent,
                threshold=self.thresholds.cpu_critical
            )
        elif cpu_percent >= self.thresholds.cpu_warning:
            level = "warning"
            self.add_alert(
                level="warning",
                category="CPU",
                message=f"CPU usage high: {cpu_percent}%",
                value=cpu_percent,
                threshold=self.thresholds.cpu_warning
            )
        
        return {
            "status": level,
            "cpu_percent": cpu_percent,
            "cpu_count": cpu_count,
            "cpu_per_core": cpu_per_core,
            "load_average": os.getloadavg()
        }
    
    def check_memory(self) -> Dict:
        """Monitor memory usage"""
        memory = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        # Check thresholds
        level = "info"
        if memory.percent >= self.thresholds.memory_critical:
            level = "critical"
            self.add_alert(
                level="critical",
                category="Memory",
                message=f"Memory usage critical: {memory.percent}%",
                value=memory.percent,
                threshold=self.thresholds.memory_critical
            )
        elif memory.percent >= self.thresholds.memory_warning:
            level = "warning"
            self.add_alert(
                level="warning",
                category="Memory",
                message=f"Memory usage high: {memory.percent}%",
                value=memory.percent,
                threshold=self.thresholds.memory_warning
            )
        
        return {
            "status": level,
            "total": memory.total,
            "available": memory.available,
            "percent": memory.percent,
            "used": memory.used,
            "free": memory.free,
            "swap_total": swap.total,
            "swap_used": swap.used,
            "swap_percent": swap.percent
        }
    
    def check_disk(self) -> Dict:
        """Monitor disk usage"""
        partitions = psutil.disk_partitions()
        disk_info = []
        worst_level = "info"
        
        for partition in partitions:
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                
                # Check thresholds
                level = "info"
                if usage.percent >= self.thresholds.disk_critical:
                    level = "critical"
                    worst_level = "critical"
                    self.add_alert(
                        level="critical",
                        category="Disk",
                        message=f"Disk usage critical on {partition.mountpoint}: {usage.percent}%",
                        value=usage.percent,
                        threshold=self.thresholds.disk_critical
                    )
                elif usage.percent >= self.thresholds.disk_warning:
                    level = "warning"
                    if worst_level != "critical":
                        worst_level = "warning"
                    self.add_alert(
                        level="warning",
                        category="Disk",
                        message=f"Disk usage high on {partition.mountpoint}: {usage.percent}%",
                        value=usage.percent,
                        threshold=self.thresholds.disk_warning
                    )
                
                disk_info.append({
                    "device": partition.device,
                    "mountpoint": partition.mountpoint,
                    "fstype": partition.fstype,
                    "total": usage.total,
                    "used": usage.used,
                    "free": usage.free,
                    "percent": usage.percent,
                    "status": level
                })
            except PermissionError:
                continue
        
        return {
            "status": worst_level,
            "partitions": disk_info
        }
    
    def check_network(self) -> Dict:
        """Monitor network statistics"""
        net_io = psutil.net_io_counters()
        connections = psutil.net_connections()
        
        # Count connection states
        conn_states = {}
        for conn in connections:
            state = conn.status
            conn_states[state] = conn_states.get(state, 0) + 1
        
        return {
            "bytes_sent": net_io.bytes_sent,
            "bytes_recv": net_io.bytes_recv,
            "packets_sent": net_io.packets_sent,
            "packets_recv": net_io.packets_recv,
            "errin": net_io.errin,
            "errout": net_io.errout,
            "dropin": net_io.dropin,
            "dropout": net_io.dropout,
            "connections": len(connections),
            "connection_states": conn_states
        }
    
    def check_processes(self) -> Dict:
        """Monitor processes"""
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                pinfo = proc.info
                if pinfo['cpu_percent'] > 10 or pinfo['memory_percent'] > 5:
                    processes.append(pinfo)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        # Sort by CPU usage
        processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
        
        return {
            "total_processes": len(list(psutil.process_iter())),
            "top_processes": processes[:10]
        }
    
    def add_alert(self, level: str, category: str, message: str,
                  value: Optional[float] = None, threshold: Optional[float] = None):
        """Add alert to list"""
        alert = Alert(
            timestamp=datetime.now().isoformat(),
            level=level,
            category=category,
            message=message,
            value=value,
            threshold=threshold
        )
        self.alerts.append(alert)
        logger.log(level.upper(), message)


class ServiceMonitor:
    """Monitor services and endpoints"""
    
    def __init__(self, thresholds: MonitoringThresholds):
        self.thresholds = thresholds
        self.alerts: List[Alert] = []
    
    def check_http_endpoint(self, url: str, expected_status: int = 200,
                           timeout: int = 10) -> Dict:
        """Check HTTP endpoint health"""
        try:
            start_time = time.time()
            response = requests.get(url, timeout=timeout)
            response_time = time.time() - start_time
            
            # Check status code
            status_ok = response.status_code == expected_status
            
            # Check response time
            level = "info"
            if response_time >= self.thresholds.response_time_critical:
                level = "critical"
                self.add_alert(
                    level="critical",
                    category="HTTP",
                    message=f"Endpoint {url} response time critical: {response_time:.2f}s",
                    value=response_time,
                    threshold=self.thresholds.response_time_critical
                )
            elif response_time >= self.thresholds.response_time_warning:
                level = "warning"
                self.add_alert(
                    level="warning",
                    category="HTTP",
                    message=f"Endpoint {url} response time high: {response_time:.2f}s",
                    value=response_time,
                    threshold=self.thresholds.response_time_warning
                )
            
            if not status_ok:
                level = "critical"
                self.add_alert(
                    level="critical",
                    category="HTTP",
                    message=f"Endpoint {url} returned status {response.status_code}",
                    value=response.status_code,
                    threshold=expected_status
                )
            
            return {
                "url": url,
                "status": level,
                "status_code": response.status_code,
                "response_time": response_time,
                "headers": dict(response.headers)
            }
        except requests.RequestException as e:
            self.add_alert(
                level="critical",
                category="HTTP",
                message=f"Endpoint {url} unreachable: {str(e)}"
            )
            return {
                "url": url,
                "status": "critical",
                "error": str(e)
            }
    
    def check_database(self, connection_string: str) -> Dict:
        """Check database connection"""
        try:
            import psycopg2
            
            start_time = time.time()
            conn = psycopg2.connect(connection_string)
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
            cur.close()
            conn.close()
            response_time = time.time() - start_time
            
            return {
                "status": "info",
                "connected": True,
                "response_time": response_time
            }
        except Exception as e:
            self.add_alert(
                level="critical",
                category="Database",
                message=f"Database connection failed: {str(e)}"
            )
            return {
                "status": "critical",
                "connected": False,
                "error": str(e)
            }
    
    def add_alert(self, level: str, category: str, message: str,
                  value: Optional[float] = None, threshold: Optional[float] = None):
        """Add alert to list"""
        alert = Alert(
            timestamp=datetime.now().isoformat(),
            level=level,
            category=category,
            message=message,
            value=value,
            threshold=threshold
        )
        self.alerts.append(alert)
        logger.log(level.upper(), message)


class AlertNotifier:
    """Send alert notifications"""
    
    def __init__(self, smtp_host: str, smtp_port: int,
                 smtp_user: str, smtp_password: str,
                 from_email: str, to_emails: List[str]):
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port
        self.smtp_user = smtp_user
        self.smtp_password = smtp_password
        self.from_email = from_email
        self.to_emails = to_emails
    
    def send_email(self, subject: str, body: str):
        """Send email notification"""
        try:
            msg = MIMEMultipart()
            msg['From'] = self.from_email
            msg['To'] = ', '.join(self.to_emails)
            msg['Subject'] = subject
            
            msg.attach(MIMEText(body, 'html'))
            
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(msg)
            
            logger.info(f"Alert email sent: {subject}")
        except Exception as e:
            logger.error(f"Failed to send email: {e}")
    
    def send_slack(self, webhook_url: str, message: str):
        """Send Slack notification"""
        try:
            payload = {
                "text": message,
                "username": "Monitoring Bot",
                "icon_emoji": ":warning:"
            }
            response = requests.post(webhook_url, json=payload)
            response.raise_for_status()
            logger.info("Alert sent to Slack")
        except Exception as e:
            logger.error(f"Failed to send Slack notification: {e}")
    
    def format_alerts_html(self, alerts: List[Alert]) -> str:
        """Format alerts as HTML"""
        html = """
        <html>
        <head>
            <style>
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #4CAF50; color: white; }
                .critical { background-color: #f44336; color: white; }
                .warning { background-color: #ff9800; color: white; }
                .info { background-color: #2196F3; color: white; }
            </style>
        </head>
        <body>
            <h2>Monitoring Alerts</h2>
            <table>
                <tr>
                    <th>Timestamp</th>
                    <th>Level</th>
                    <th>Category</th>
                    <th>Message</th>
                    <th>Value</th>
                    <th>Threshold</th>
                </tr>
        """
        
        for alert in alerts:
            html += f"""
                <tr class="{alert.level}">
                    <td>{alert.timestamp}</td>
                    <td>{alert.level.upper()}</td>
                    <td>{alert.category}</td>
                    <td>{alert.message}</td>
                    <td>{alert.value if alert.value else 'N/A'}</td>
                    <td>{alert.threshold if alert.threshold else 'N/A'}</td>
                </tr>
            """
        
        html += """
            </table>
        </body>
        </html>
        """
        
        return html


def main():
    """Main monitoring function"""
    # Configure logging
    logger.add("monitoring_{time}.log", rotation="1 day", retention="7 days")
    
    # Initialize monitors
    thresholds = MonitoringThresholds()
    system_monitor = SystemMonitor(thresholds)
    service_monitor = ServiceMonitor(thresholds)
    
    logger.info("Starting system monitoring...")
    
    # Collect metrics
    results = {
        "timestamp": datetime.now().isoformat(),
        "hostname": os.uname().nodename,
        "cpu": system_monitor.check_cpu(),
        "memory": system_monitor.check_memory(),
        "disk": system_monitor.check_disk(),
        "network": system_monitor.check_network(),
        "processes": system_monitor.check_processes(),
    }
    
    # Check services
    services = [
        {"url": "http://localhost:8000/health", "name": "API"},
        {"url": "http://localhost:3000", "name": "Frontend"},
    ]
    
    results["services"] = []
    for service in services:
        result = service_monitor.check_http_endpoint(service["url"])
        result["name"] = service["name"]
        results["services"].append(result)
    
    # Combine alerts
    all_alerts = system_monitor.alerts + service_monitor.alerts
    results["alerts"] = [asdict(alert) for alert in all_alerts]
    
    # Save results
    output_file = f"monitoring_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    logger.info(f"Monitoring report saved: {output_file}")
    
    # Send alerts if any critical
    critical_alerts = [a for a in all_alerts if a.level == "critical"]
    if critical_alerts:
        logger.warning(f"Found {len(critical_alerts)} critical alerts")
        # Uncomment to enable notifications
        # notifier = AlertNotifier(...)
        # notifier.send_email("Critical System Alerts", notifier.format_alerts_html(critical_alerts))
    
    logger.info("Monitoring completed")
    return 0 if not critical_alerts else 1


if __name__ == "__main__":
    sys.exit(main())
