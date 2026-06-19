{{/* routing 코덱 — 모듈의 `spec.routing` 선언을 라우팅 provider 별 매니페스트로 렌더한다.
     provider 는 platform.provides.routing.provider 에서 오고, bee 가 .Values.provides 로 전달한다.
     모듈이 보는 인터페이스는 provider 와 무관한 `spec.routing` 한 가지이며, provider 템플릿이
     ingress class·주석·부속 CR(kong=KongPlugin)을 소유해 provider 마다 다르게 렌더한다(kong↔nginx).
     모듈 입력과 출력 계약은 provider 가 바뀌어도 동일하다. */}}

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
