{{/* Malformed helpers template with syntax errors */}}
{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels -}}
{{- range $key, $value := .Values.commonLabels }}
{{ $key }}: {{ $value }}
{{- end -}}
{{- end -}
{{/* Missing closing brace in the end tag */}}

{{- define "mychart.fullname" -}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{/* Missing closing brace in the end tag */}}