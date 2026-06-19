{{/* G28 ③ provider-rendering 코덱 (routing) — capability `routing` 을 provider 별 렌더로 dispatch.
     provider = platform.provides.routing.provider(G36, bee 가 .Values.provides 로 전달). **seam 인터페이스 =
     동결 어휘 `spec.routing`** — 투기 아님(어휘는 ①, 안정). provider 템플릿이 ingress class·주석·부속 CR
     (kong=KongPlugin)을 소유 = pluggability(kong↔nginx 다르게 렌더). 어휘·출력 계약 동일, 경계: 선언+렌더(G26). */}}

{{- define "bee.routing.provider" -}}
{{- (((.Values.provides | default dict).routing) | default dict).provider | default "kong" -}}
{{- end -}}

{{- define "bee.routing.class" -}}
{{- if eq (include "bee.routing.provider" .) "nginx" }}nginx{{ else }}kong{{ end -}}
{{- end -}}

{{- /* provider 별 ingress 주석(rateLimit/auth 어휘 → provider 표현). 빈 문자열이면 ingress 가 주석 생략. */ -}}
{{- define "bee.routing.annotations" -}}
{{- $p := include "bee.routing.provider" . -}}
{{- if eq $p "kong" -}}
{{- /* kong: rateLimit·jwt → KongPlugin 연결 주석 */ -}}
{{- $plugins := list -}}
{{- range $i, $r := .Values.spec.routing -}}
{{- if $r.rateLimit }}{{- $plugins = append $plugins (printf "%s-ratelimit-%d" $.Release.Name $i) -}}{{- end -}}
{{- if eq ($r.auth | default "") "jwt" }}{{- $plugins = append $plugins (printf "%s-jwt-%d" $.Release.Name $i) -}}{{- end -}}
{{- end -}}
{{- with $plugins }}konghq.com/plugins: {{ join "," . | quote }}{{ end -}}
{{- else if eq $p "nginx" -}}
{{- /* nginx: rateLimit → limit-rpm 주석(부속 CR 없음 — annotation 만) */ -}}
{{- with (.Values.spec.routing | first) -}}{{- with .rateLimit }}nginx.ingress.kubernetes.io/limit-rpm: {{ .minute | quote }}{{ end -}}{{- end -}}
{{- end -}}
{{- end -}}
