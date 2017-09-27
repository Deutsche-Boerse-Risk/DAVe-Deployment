{{- define "floatToInt" -}}
{{- $intPart := mul (toString . | split ".")._0 1000 -}}
{{- $decPart :=  cat (toString . | split ".")._1 "000" | nospace | trunc 3 -}}
{{- add $intPart $decPart -}}
{{- end -}}

{{- define "cpuToMilliCPU" -}}
    {{- $cpuLimit := .cpu -}}
    {{- if hasSuffix "m" (toString $cpuLimit) -}}
        {{- int ($cpuLimit | trimSuffix "m") -}}
    {{- else -}}
        {{- include "floatToInt" $cpuLimit -}}
    {{- end -}}
{{- end -}}

{{- define "memoryToBytes" -}}
    {{- $memoryLimit := .memory -}}
    {{- if hasSuffix "K" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "K") -}}
        {{- mul $memoryLimit 1000 -}}
    {{- else if hasSuffix "M" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "M") -}}
        {{- mul $memoryLimit 1000 1000 -}}
    {{- else if hasSuffix "G" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "G") -}}
        {{- mul $memoryLimit 1000 1000 1000 -}}
    {{- else if hasSuffix "T" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "T") -}}
        {{- mul $memoryLimit 1000 1000 1000 1000 -}}
    {{- else if hasSuffix "P" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "P") -}}
        {{- mul $memoryLimit 1000 1000 1000 1000 1000 -}}
    {{- else if hasSuffix "E" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "E") -}}
        {{- mul $memoryLimit 1000 1000 1000 1000 1000 1000 -}}
    {{- else if hasSuffix "Ki" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "Ki") -}}
        {{- mul $memoryLimit 1024 -}}
    {{- else if hasSuffix "Mi" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "Mi") -}}
        {{- mul $memoryLimit 1024 1024 -}}
    {{- else if hasSuffix "Gi" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "Gi") -}}
        {{- mul $memoryLimit 1024 1024 1024 -}}
    {{- else if hasSuffix "Ti" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "Ti") -}}
        {{- mul $memoryLimit 1024 1024 1024 1024 -}}
    {{- else if hasSuffix "Pi" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "Pi") -}}
        {{- mul $memoryLimit 1024 1024 1024 1024 1024 -}}
    {{- else if hasSuffix "Ei" (toString $memoryLimit) -}}
        {{- $memoryLimit := int ($memoryLimit | trimSuffix "Ei") -}}
        {{- mul $memoryLimit 1024 1024 1024 1024 1024 1024 -}}
    {{- else -}}
        {{- $memoryLimit -}}
    {{- end -}}
{{- end -}}

