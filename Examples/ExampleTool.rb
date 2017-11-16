# REVIEW: Doesn't it look odd to call this YourExtensionNamespace?
# REVIEW: Is this really an example or is it a test? It was designed to be a test. Should I label it TestTool and name the folder tests instead?
module YourExtensionNamespace

  # Test code to see that calculated color really matches the one SketchUp
  # uses for face shading.
  #
  # If custom shading code is successful the face center points drawn by
  # ExampleTool should blend into their faces, unless are shown through another
  # face or cover the edges binding the face.
  class ExampleTool

    def activate
      Sketchup.active_model.active_view.invalidate
    end

    def draw(view)
      view.model.active_entities.each do |face|
        next unless face.is_a?(Sketchup::Face)
        view.draw_points(
          [face.bounds.center],
          10,
          2,
          FaceShading.shaded_face_color(face)
        )
      end
    end

    def resume(view)
      view.invalidate
    end

  end

  UI.menu("Plugins").add_item("Test Color Shading") {
    Sketchup.active_model.select_tool(ExampleTool.new)
  }

end
