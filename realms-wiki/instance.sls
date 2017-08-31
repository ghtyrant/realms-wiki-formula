{% set realms = salt['pillar.get']('realms-wiki', {}) %}

{% for instance, config in realms.get('instances', {}).items() %}
realms_{{ instance }}_web_dir:
  file.directory:
    - name: {{ config.base_path }}
    - user: {{ realms.web_user }}
    - group: {{ realms.web_group }}
    - mode: 755
    - makedirs: true

realms_{{ instance }}_venv:
  virtualenv.managed:
    - name: {{ config.base_path }}/.venv
    - pip_pkgs:
        - realms-wiki
        {% if config.get('use_postgresql', False) %}
        - psycopg2
        {% endif %}

        {% if config.get('use_whoosh', False) %}
        - whoosh
        {% endif %}


realms_{{ instance }}_config:
  file.serialize:
    - name: {{ config.base_path }}/realms-wiki.json
    - dataset: {{ config.get('config', {}) }}
    - user: {{ realms.web_user }}
    - group: {{ realms.web_group }}
    - mode: 600
    - formatter: json
    {% if config.get('service', False) %}
    - watch_in:
        - service: realms_{{ instance }}_service
    {% endif %}

{% if config.get('service', False) %}
realms_{{ instance }}_service_file:
  file.managed:
    - name: /etc/systemd/system/realms-{{ instance }}.service
    - source: salt://realms-wiki/files/realms-wiki.service
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - context:
        name: {{ instance }}
        base_path: {{ config.base_path }}
        web_user: {{ realms.web_user }}
        web_group: {{ realms.web_group }}
        bind_address: {{ config.bind_address }}
        num_workers: {{ config.num_workers }}

realms_{{ instance }}_service:
  service.running:
    - name: realms-{{ instance }}
    - enable: True
{% endif %}

{% endfor %}
