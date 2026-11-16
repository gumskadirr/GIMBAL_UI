.pragma library

// Every control below `item` that can take focus (buttons, fields, lists, switches, sliders); plain items
// and layouts report Qt.NoFocus. Hidden ones are included on purpose: they must be disabled as well.
// Used to check that a page has no enabled input while the device protocol is missing.
function interactiveControls(item, found) {
    found = found || []
    for (let i = 0; i < item.children.length; ++i) {
        const child = item.children[i]
        if (child.focusPolicy !== undefined && child.focusPolicy !== Qt.NoFocus)
            found.push(child)
        interactiveControls(child, found)
    }
    return found
}
