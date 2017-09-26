{{/* vim: set filetype=mustache: */}}

{{- define "labelsMap" -}}
{{- range $key, $value := .Values.labels }}{{ $key }}={{ $value }},{{- end }}
{{- end -}}

{{- define "sidecar.labels" -}}
{{ include "labelsMap" . | trimSuffix "," | quote }}
{{- end -}}