describe 'Calculator', ->
  it 'should sum', ->
    expect(1 + 1).toBe(2)
    expect(1 + 2).toBe(3)

  # Jest requires `describe` callback to return undefined
  return undefined
