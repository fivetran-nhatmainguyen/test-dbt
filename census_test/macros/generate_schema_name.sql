{#
    Census rule: this macro must live ALONE in its own file. If another macro is defined
    in the same file, Census's dbt compile step fails with:
    'dbt found two macros named "generate_schema_name"' and the run is halted.
    (see giza app/models/dbt_project.rb#extract_errors)
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
