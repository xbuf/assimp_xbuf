package assimp;

public class aiTextureType {
	/** Dummy value.
	 *
	 *  No texture, but the value to be used as 'texture semantic' 
	 *  (#aiMaterialProperty::mSemantic) for all material properties 
	 *  *not* related to textures.
	 */
	public final static int aiTextureType_NONE = 0x0;



    /** The texture is combined with the result of the diffuse
	 *  lighting equation.
     */
    public final static int aiTextureType_DIFFUSE = 0x1;

	/** The texture is combined with the result of the specular
	 *  lighting equation.
     */
    public final static int aiTextureType_SPECULAR = 0x2;

	/** The texture is combined with the result of the ambient
	 *  lighting equation.
     */
    public final static int aiTextureType_AMBIENT = 0x3;

	/** The texture is added to the result of the lighting
	 *  calculation. It isn't influenced by incoming light.
     */
    public final static int aiTextureType_EMISSIVE = 0x4;

	/** The texture is a height map.
	 *
	 *  By convention, higher gray-scale values stand for
	 *  higher elevations from the base height.
     */
    public final static int aiTextureType_HEIGHT = 0x5;

	/** The texture is a (tangent space) normal-map.
	 *
	 *  Again, there are several conventions for tangent-space
	 *  normal maps. Assimp does (intentionally) not 
	 *  distinguish here.
     */
    public final static int aiTextureType_NORMALS = 0x6;

	/** The texture defines the glossiness of the material.
	 *
	 *  The glossiness is in fact the exponent of the specular
	 *  (phong) lighting equation. Usually there is a conversion
	 *  function defined to map the linear color values in the
	 *  texture to a suitable exponent. Have fun.
    */
    public final static int aiTextureType_SHININESS = 0x7;

	/** The texture defines per-pixel opacity.
	 *
	 *  Usually 'white' means opaque and 'black' means 
	 *  'transparency'. Or quite the opposite. Have fun.
    */
    public final static int aiTextureType_OPACITY = 0x8;

	/** Displacement texture
	 *
	 *  The exact purpose and format is application-dependent.
     *  Higher color values stand for higher vertex displacements.
    */
    public final static int aiTextureType_DISPLACEMENT = 0x9;

	/** Lightmap texture (aka Ambient Occlusion)
	 *
	 *  Both 'Lightmaps' and dedicated 'ambient occlusion maps' are
	 *  covered by this material property. The texture contains a
	 *  scaling value for the final color value of a pixel. Its
	 *  intensity is not affected by incoming light.
    */
    public final static int aiTextureType_LIGHTMAP = 0xA;

	/** Reflection texture
	 *
	 * Contains the color of a perfect mirror reflection.
	 * Rarely used, almost never for real-time applications.
    */
    public final static int aiTextureType_REFLECTION = 0xB;

	/** Unknown texture
	 *
	 *  A texture reference that does not match any of the definitions 
	 *  above is considered to be 'unknown'. It is still imported,
	 *  but is excluded from any further postprocessing.
    */
    public final static int aiTextureType_UNKNOWN = 0xC;
}
