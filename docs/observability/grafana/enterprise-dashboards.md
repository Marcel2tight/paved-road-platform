# Enterprise Grafana Dashboards

## Objective

Build Grafana Cloud dashboards for the Paved Road Platform using Google Cloud Monitoring as the initial data source.

This allows platform engineers and developers to visualize Cloud Run reliability, performance, scaling, and SLO health without deploying additional Prometheus infrastructure during the initial implementation.

## Current Architecture

```text
Cloud Run Services
        ↓
Google Cloud Monitoring
        ↓
Grafana Cloud
        ↓
Platform and Developer Dashboards
Dashboard Strategy

The first Grafana dashboards are based on Google Cloud Monitoring metrics already collected from Cloud Run.

Prometheus-compatible application metrics exposed through /metrics are documented separately and reserved for future Managed Prometheus integration.

Dashboards
Dashboard	Purpose
Platform Overview	High-level health of the paved road platform
Cloud Run Operations	Runtime performance of Cloud Run services
Reliability and SLOs	Error rate, latency, availability, and burn-rate views
Developer Experience	Service-level visibility for teams using the paved road
Initial Data Source
Item	Value
Grafana	Grafana Cloud
Data Source	Google Cloud Monitoring
GCP Project	imposing-fx-413205
Authentication	Google JWT File
Service Account	grafana-monitoring-reader@imposing-fx-413205.iam.gserviceaccount.com
Recommended Panels
Platform Overview
Cloud Run request count
5xx error count
Request latency
Instance count
CPU utilization
Memory utilization
SLO status
Burn-rate alert status
Cloud Run Operations
Request rate by service
Response latency
Container CPU utilization
Container memory utilization
Instance count
Revision-level traffic
Reliability and SLOs
Availability
Error rate
Latency percentile
SLO burn rate
Failed request trend
Alerting history
Developer Experience
Service health
Recent errors
Request volume
Latency
Active revisions
Ownership labels
Enterprise Value

Grafana dashboards provide a centralized operational view across the Paved Road Platform.

This improves:

platform visibility
developer self-service
incident response
reliability engineering
executive-level reporting
future readiness for Managed Prometheus and OpenTelemetry
Future Enhancements
Import/export dashboard JSON
Add Managed Service for Prometheus
Add PromQL-based custom metric panels
Add FinOps dashboards from BigQuery billing export
Add Vertex AI operational dashboards
Link Backstage catalog entities directly to Grafana dashboards