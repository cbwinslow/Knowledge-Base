# Testing Tools

Comprehensive testing tools for unit, integration, E2E, performance, and security testing.

## Unit Testing Frameworks

### Jest (JavaScript/TypeScript)
**Purpose:** JavaScript testing framework  
**Configuration:**
```yaml
tool:
  name: jest
  type: unit_testing
  languages: [javascript, typescript]
  config_file: jest.config.js
  features:
    - snapshot_testing
    - code_coverage
    - mocking
    - async_testing
  command: jest
  args:
    - "--coverage"
    - "--verbose"
```

**Example Configuration (jest.config.js):**
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

### Pytest (Python)
**Purpose:** Python testing framework  
**Configuration:**
```yaml
tool:
  name: pytest
  type: unit_testing
  languages: [python]
  config_file: pytest.ini
  features:
    - fixtures
    - parametrization
    - plugins
    - coverage
  command: pytest
  args:
    - "--cov=src"
    - "--cov-report=html"
    - "--cov-report=term"
```

### JUnit (Java)
**Purpose:** Java testing framework  
**Configuration:**
```yaml
tool:
  name: junit
  type: unit_testing
  languages: [java]
  version: "5"
  features:
    - annotations
    - assertions
    - test_suites
    - parameterized_tests
```

### RSpec (Ruby)
**Purpose:** Ruby testing framework  
**Configuration:**
```yaml
tool:
  name: rspec
  type: unit_testing
  languages: [ruby]
  config_file: .rspec
  features:
    - describe_blocks
    - expectations
    - mocking
    - shared_examples
```

## Integration Testing

### Supertest (Node.js)
**Purpose:** HTTP API testing  
**Configuration:**
```yaml
tool:
  name: supertest
  type: integration_testing
  languages: [javascript, typescript]
  use_case: api_testing
  features:
    - http_assertions
    - express_integration
    - async_support
```

### TestContainers
**Purpose:** Integration testing with Docker containers  
**Configuration:**
```yaml
tool:
  name: testcontainers
  type: integration_testing
  languages: [java, python, nodejs, go]
  features:
    - database_containers
    - message_queue_containers
    - service_containers
  supported_services:
    - postgresql
    - mysql
    - mongodb
    - redis
    - kafka
    - elasticsearch
```

## End-to-End Testing

### Cypress
**Purpose:** E2E testing for web applications  
**Configuration:**
```yaml
tool:
  name: cypress
  type: e2e_testing
  config_file: cypress.config.js
  features:
    - time_travel
    - automatic_waiting
    - screenshots
    - video_recording
    - network_stubbing
  browsers:
    - chrome
    - firefox
    - edge
```

**Example Configuration:**
```javascript
module.exports = {
  e2e: {
    baseUrl: 'http://localhost:3000',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: true,
    screenshotOnRunFailure: true
  }
};
```

### Playwright
**Purpose:** Cross-browser E2E testing  
**Configuration:**
```yaml
tool:
  name: playwright
  type: e2e_testing
  config_file: playwright.config.ts
  features:
    - multi_browser
    - auto_waiting
    - screenshots
    - video_recording
    - network_interception
  browsers:
    - chromium
    - firefox
    - webkit
```

### Selenium
**Purpose:** Browser automation testing  
**Configuration:**
```yaml
tool:
  name: selenium
  type: e2e_testing
  languages: [java, python, javascript, csharp, ruby]
  drivers:
    - chromedriver
    - geckodriver
    - safaridriver
  features:
    - cross_browser
    - grid_support
    - mobile_testing
```

## Performance Testing

### JMeter
**Purpose:** Load and performance testing  
**Configuration:**
```yaml
tool:
  name: jmeter
  type: performance_testing
  config_file: test_plan.jmx
  features:
    - load_testing
    - stress_testing
    - spike_testing
    - endurance_testing
  protocols:
    - http
    - https
    - ftp
    - jdbc
    - jms
```

### K6
**Purpose:** Modern load testing tool  
**Configuration:**
```yaml
tool:
  name: k6
  type: performance_testing
  script_language: javascript
  features:
    - scripting
    - cli_friendly
    - ci_cd_integration
    - cloud_execution
  metrics:
    - http_req_duration
    - http_req_failed
    - http_reqs
    - vus
```

**Example Script:**
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  let response = http.get('https://api.example.com');
  check(response, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

### Gatling
**Purpose:** High-performance load testing  
**Configuration:**
```yaml
tool:
  name: gatling
  type: performance_testing
  script_language: scala
  features:
    - high_performance
    - detailed_reports
    - protocol_support
    - real_time_monitoring
```

## API Testing

### Postman/Newman
**Purpose:** API testing and automation  
**Configuration:**
```yaml
tool:
  name: newman
  type: api_testing
  collection_file: postman_collection.json
  environment_file: environment.json
  features:
    - collection_runner
    - cli_execution
    - ci_cd_integration
    - reporting
  reporters:
    - cli
    - json
    - html
```

### REST Assured (Java)
**Purpose:** REST API testing in Java  
**Configuration:**
```yaml
tool:
  name: rest_assured
  type: api_testing
  languages: [java]
  features:
    - fluent_api
    - json_path
    - xml_path
    - authentication
    - request_specification
```

## Security Testing

### OWASP ZAP
**Purpose:** Security testing and scanning  
**Configuration:**
```yaml
tool:
  name: owasp_zap
  type: security_testing
  features:
    - active_scanning
    - passive_scanning
    - spider
    - ajax_spider
    - api_scanning
  scan_types:
    - baseline
    - full
    - api
```

### Burp Suite
**Purpose:** Web application security testing  
**Configuration:**
```yaml
tool:
  name: burp_suite
  type: security_testing
  features:
    - proxy
    - scanner
    - intruder
    - repeater
    - decoder
```

## Mobile Testing

### Appium
**Purpose:** Mobile app automation  
**Configuration:**
```yaml
tool:
  name: appium
  type: mobile_testing
  platforms: [ios, android]
  features:
    - native_apps
    - hybrid_apps
    - web_apps
    - cross_platform
```

### Detox (React Native)
**Purpose:** React Native E2E testing  
**Configuration:**
```yaml
tool:
  name: detox
  type: mobile_testing
  platforms: [ios, android]
  features:
    - gray_box_testing
    - synchronization
    - device_farm_integration
```

## Test Management

### TestRail
**Purpose:** Test case management  
**Configuration:**
```yaml
tool:
  name: testrail
  type: test_management
  features:
    - test_cases
    - test_runs
    - reporting
    - integrations
```

## CI/CD Integration Example

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Jest
        run: npm test -- --coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
    steps:
      - uses: actions/checkout@v3
      - name: Run integration tests
        run: npm run test:integration

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Cypress
        uses: cypress-io/github-action@v5
        with:
          start: npm start
          wait-on: 'http://localhost:3000'

  performance-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run K6
        uses: grafana/k6-action@v0.3.0
        with:
          filename: tests/performance/load-test.js
```

## Best Practices

1. **Test Pyramid** - More unit tests, fewer E2E tests
2. **Fast Feedback** - Keep tests fast and reliable
3. **Isolation** - Tests should be independent
4. **Coverage** - Aim for 80%+ code coverage
5. **Continuous Testing** - Run tests in CI/CD
6. **Test Data** - Use fixtures and factories
7. **Flaky Tests** - Investigate and fix immediately
8. **Parallel Execution** - Run tests in parallel
9. **Clear Assertions** - Make test failures obvious
10. **Cleanup** - Clean up test data and resources
