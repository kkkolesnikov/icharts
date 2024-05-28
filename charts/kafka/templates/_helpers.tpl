{{/*
Expand the name of the chart.
*/}}
{{- define "kafka.names.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kafka.names.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kafka.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka.labels" -}}
helm.sh/chart: {{ include "kafka.chart" . }}
{{ include "kafka.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kafka.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kafka.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kafka.names.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the namespace to use
*/}}
{{- define "kafka.namespace" -}}
{{- if .Values.namespace.create }}
{{- default .Values.namespace.name }}
{{- else }}
{{- default "default" }}
{{- end }}
{{- end }}

{{/*
Controller name
*/}}
{{- define "kafka.controller.name" -}}
{{- printf "%s-controller" ((include "kafka.names.fullname" . )) | trunc 63 | trimSuffix "-" }}
{{- end}}

{{/*
Broker name
*/}}
{{- define "kafka.broker.name" -}}
{{- printf "%s-broker" ((include "kafka.names.fullname" . )) | trunc 63 | trimSuffix "-" }}
{{- end}}

{{/*
Controller voters
*/}}\
{{- define "kafka.controller.voters" -}}
  {{- $controllerVoters := list -}}
  {{- $releaseNamespace := include "kafka.namespace" . -}}
  {{- $controllerName := include "kafka.controller.name" . -}}
  {{- range $i := until (int .Values.controller.replicaCount) -}}
  {{- $nodeId := $i -}}
  {{- $nodeAddress := printf "%s-%d.%s-headless.%s.svc.cluster.local:%d" $controllerName (int $i) $controllerName $releaseNamespace (int $.Values.controller.port ) -}}
  {{- $controllerVoters = append $controllerVoters (printf "%d@%s" $nodeId $nodeAddress ) -}}
  {{- end -}}
  {{- join "," $controllerVoters -}}
{{- end}}

{{/*listeners.security.protocol.map*/}}
{{- define "listeners.security.protocol.map" }}
  {{- $protocolMap := list -}}
  {{- $protocolMap = append $protocolMap "CONTROLLER:PLAINTEXT" }}
  {{- $protocolMap = append $protocolMap "INTERNAL:PLAINTEXT" }}
  {{- if .Values.broker.externalAccess.enabled }}
  {{- $externalListenerMap := printf "%s:%s" .Values.broker.externalAccess.listenerProtocol .Values.broker.externalAccess.kafkaProtocol }}
  {{- $protocolMap = append $protocolMap $externalListenerMap }}
  {{- end -}}
  {{- join "," $protocolMap -}}
{{- end }}

{{/*kafka.listeners*/}}
{{- define "kafka.listeners" }}
  {{- $listeners := list -}}
  {{- $listeners = append $listeners (printf "INTERNAL://0.0.0.0:%d" (int .Values.broker.port)) }}
  {{- if .Values.broker.externalAccess.enabled }}
  {{- $externalListener := printf "%s://:%d" .Values.broker.externalAccess.listenerProtocol (int .Values.broker.externalAccess.port) }}
  {{- $listeners = append $listeners $externalListener }}
  {{- end -}}
  {{- join "," $listeners -}}
{{- end }}


{{/*
kafka.listeners

INTERNAL://$(POD_NAME).{{ include "kafka.broker.name" . }}-headless.{{ include "kafka.namespace" . }}.svc.cluster.local:{{ .Values.broker.port }},
EXTERNAL://$(HOST_IP):3000$(POD_INDEX)

$(POD_NAME), $(HOST_IP), $(POD_INDEX) to be substituted by actual values during POD initialization in a cluster.
*/}}
{{- define "kafka.advertised.listeners" }}
  {{- $listeners := list -}}
  {{- $brokerName := include "kafka.broker.name" . }}
  {{- $namespace := include "kafka.namespace" . -}}
  {{- $listeners = append $listeners (printf "INTERNAL://$(POD_NAME).%s-headless.%s.svc.cluster.local:%d" $brokerName $namespace (int .Values.broker.port)) }}
  {{- if .Values.broker.externalAccess.enabled }}
  {{- $externalListener := printf "%s://$(HOST_IP):%d$(POD_INDEX)" .Values.broker.externalAccess.listenerProtocol (int .Values.broker.externalAccess.nodePortPrefix) }}
  {{- $listeners = append $listeners $externalListener }}
  {{- end -}}
  {{- join "," $listeners -}}
{{- end }}
