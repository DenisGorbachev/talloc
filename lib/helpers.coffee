export display = (tasks, level) ->
  for task in tasks
    console.info(' '.repeat(level * 2) + '- ' + task.type)
    display(task.children, level + 1)
