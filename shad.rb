module FaceShading

  # Get the (unshaded) color of viewed side of a face.
  # If face has texture, simply return the average color.
  # For now material inherited from parent group/component is ignored.
  #
  # face   - A Face Entity.
  # plane  - Plane used to determine what side of faces is viewed expressed
  #          according to Geom documentation (default: face's plane).
  # camera - A Camera object (default: the camera of the same model face is in).
  #
  # Returns Color object.
  def self.face_color(face, plane = nil, camera = nil)
    plane ||= face.plane
    camera ||= face.model.active_view.camera

    if back_of_plane?(plane, camera.eye)
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

  # Shade a color as it would be shaded if drawn to a face at a certain plane
  # and shown in a certain view.
  #
  # color  - Color object to base shaded color of.
  # plane  - Plane used for shading expressed according to Geom documentation.
  # view   - View object.
  def self.shade_color(color, plane, view)
    si = view.model.shadow_info
    light = sun_for_shading?(si) ? si["Light"]/100.0 : 0.81
    dark = sun_for_shading?(si) ? si["Dark"]/100.0 : 0.2
    shading = shade_value(plane, view)
    shift = 0.2 + dark + shading*light

    Sketchup::Color.new(*color.to_a[0, 3].map { |c| [(c*shift).to_i, 255].min })
  end

  # Get the shaded color of viewed side of a face.
  #
  # face  - A Face.
  # plane - Plane used for shading expressed according to Geom documentation
  #         (default: face's plane).
  #
  # Returns Color.
  def self.shaded_face_color(face, plane = nil)
    plane ||= face.plane

    shade_color(face_color(face, plane), plane, face.model.active_view)
  end

  # Check what side of face is being viewed.
  # Assume face is in same coordinate system as camera.
  #
  # face   - A Face entity.
  # camera - A Camera object (default: the camera of the same model face is in).
  #
  # Returns Boolean.
  def self.view_back_face?(face, camera = nil)
    camera ||= face.model.active_view.camera

    back_of_plane?(face.plane, camera.eye)
  end

  private

  def self.back_of_plane?(plane, point)
    (point - point.project_to_plane(plane)) % plane_normal(plane) < 0
  end

  def self.plane_normal(plane)
    return plane[1].clone if plane.size == 2
    a, b, c, _ = plane

    Geom::Vector3d.new(a, b, c)
  end

  # Returns Float in interval 0.0 to 1.0 of how much face should be shaded,
  # 0.0 being the darkest and 1.0 lightest.
  #
  # plane - Plane used for shading expressed according to Geom documentation.
  # view  - Sketchup::View object.
  #
  # Examples
  #
  #   model = Sketchup.active_model
  #   shade_value(model.selection.first.normal, model.active_view)
  #
  # Returns float.
  def self.shade_value(plane, view)
    si = view.model.shadow_info
    normal = plane_normal(plane)
    normal.reverse! if back_of_plane?(plane, view.camera.eye)
    reference =
      if sun_for_shading?(si)
        si["SunDirection"]
      else
        (view.camera.eye - view.camera.target).normalize
      end
    value = normal.normalize % reference

    sun_for_shading?(si) ? [value, 0].max : value.abs
  end

  def self.sun_for_shading?(si)
    # If shadows are enabled SketchUp uses sun for shading regardless of
    # the UseSunForAllShading setting.
    si["UseSunForAllShading"] || si["DisplayShadows"]
  end

end
