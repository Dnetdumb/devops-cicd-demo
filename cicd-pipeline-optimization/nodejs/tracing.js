const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter(),
  metricExporter: new OTLPMetricExporter(),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
