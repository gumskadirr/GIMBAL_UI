.pragma library
// Camera framing per model (JSON of the model object -> { center, distance }), shared by all views: a second
// RuntimeLoader of the same files may never report the bounds of a part, so a view reuses what another measured.
var cache = {}
