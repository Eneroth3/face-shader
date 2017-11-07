module FaceShading

  # Get color of face (not shaded).
  # If face has texture, simply return the average color.
  # For now material inherited from parent group/component is ignored.
  #
  # face - A Face Entity.
  #
  # Returns Color object.
  def self.face_color(face)
    if view_back_face?(face)
      if face.back_material
        face.back_material.color
      else
        face.model.rendering_options["FaceBackColor"]
      end
    else
      if face.material
        face.material.color
      else
        face.model.rendering_options["FaceFrontColor"]
      end
    end
  end

  # Shade a color as it would be shaded if drawn to a face with a certain normal
  # and shown in a certain view.
  #
  # color  - Color object to base shaded color of.
  # normal - Vector3d.
  # view   - View object.
  def self.shade_color(color, normal, view)
    si = view.model.shadow_info
    light = sun_for_shading?(si) ? si["Light"]/100.0 : 0.81
    dark = sun_for_shading?(si) ? si["Dark"]/100.0 : 0.2
    shading = shade_value(normal, view)
    shift = 0.2 + dark + shading*light

    Sketchup::Color.new(*color.to_a[0, 3].map { |c| [(c*shift).to_i, 255].min })
  end

  # Get the shaded color of a face.
  #
  # face - A Face.
  #
  # Returns Color.
  def self.shaded_face_color(face)
    shade_color(face_color(face), face.normal, face.model.active_view)
  end

  # Check what side of face is being viewed.
  # Assume face is in same coordinate system as camera.
  #
  # face - A Face entity.
  # camera - A Camera object (default: the camera of the same model fce is in).
  #
  # Returns Boolean.
  def self.view_back_face?(face, camera = nil)
    camera ||= face.model.active_view.camera
    (camera.eye - camera.eye.project_to_plane(face.plane)) % face.normal < 0
  end

  private

  # Returns Float in interval 0.0 to 1.0 of how much face should be shaded,
  # 0.0 being the darkest and 1.0 lightest.
  #
  # normal - Normal Vector3d.
  # view   - Sketchup::View object.
  #
  # Examples
  #
  #   model = Sketchup.active_model
  #   shade_value(model.selection.first.normal, model.active_view)
  #
  # Returns float.
  def self.shade_value(normal, view)
    si = view.model.shadow_info
    reference =
      if sun_for_shading?(si)
        si["SunDirection"]
      else
        (view.camera.eye - view.camera.target).normalize
      end
      value = normal % reference

      sun_for_shading?(si) ? [value, 0].max : value.abs
  end

  def self.sun_for_shading?(si)
    # If shadows are enabled SketchUp uses sun for shading regardless of
    # the UseSunForAllShading setting.
    si["UseSunForAllShading"] || si["DisplayShadows"]
  end

end

# Test code to see that calculated color really matches the one SketchUp
# uses for face shading.
#
# If customs hading code is successful the points drawn by TestTool should being
# invisible unless they represent a face hidden behind another face or cover
# their faces' edges.
class TestTool

  def activate
    Sketchup.active_model.active_view.invalidate
  end

  def draw(view)
    view.model.active_entities.each do |face|
      next unless face.is_a?(Sketchup::Face)
      view.draw_points([face.bounds.center], 10, 2, FaceShading.shaded_face_color(face))
    end
  end

  def resume(view)
    view.invalidate
  end

end
Sketchup.active_model.select_tool(TestTool.new)
