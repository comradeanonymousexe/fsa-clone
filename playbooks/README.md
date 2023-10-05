# Playbooks - yviel's FSA FSA_VERSION_STRING
Some machines need truly custom configuration, and this is the place to put it.

Any ansible playbooks put here can be included in your machines' configurations.

#### Example
Small ansible playbook, `playbooks/myplaybook.yml`
```yaml
- hosts: my-host
  # you can skip gather_facts
  gather_facts: false
  tasks:
    - name: "install htop"
      ansible.builtin.apt:
        pkg:
          - htop
```

And calling it in `config/my-host`

```yaml
fsa:
  playbooks:
    - myplaybook
```
