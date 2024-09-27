{{- define "rainstone.backend.fullname" -}}
{{- printf "%s-backend" .Release.Name -}}
{{- end -}}

{{- define "rainstone.frontend.fullname" -}}
{{- printf "%s-frontend" .Release.Name -}}
{{- end -}}
