package assimp;

public class aiShadingMode {
    /** Flat shading. Shading is done on per-face base, 
     *  diffuse only. Also known as 'faceted shading'.
     */
	public final static int aiShadingMode_Flat = 0x1;

    /** Simple Gouraud shading. 
     */
	public final static int aiShadingMode_Gouraud =	0x2;

    /** Phong-Shading -
     */
	public final static int aiShadingMode_Phong = 0x3;

    /** Phong-Blinn-Shading
     */
	public final static int aiShadingMode_Blinn	= 0x4;

    /** Toon-Shading per pixel
     *
	 *  Also known as 'comic' shader.
     */
	public final static int aiShadingMode_Toon = 0x5;

    /** OrenNayar-Shading per pixel
     *
     *  Extension to standard Lambertian shading; taking the
     *  roughness of the material into account
     */
	public final static int aiShadingMode_OrenNayar = 0x6;

    /** Minnaert-Shading per pixel
     *
     *  Extension to standard Lambertian shading, taking the
     *  "darkness" of the material into account
     */
	public final static int aiShadingMode_Minnaert = 0x7;

    /** CookTorrance-Shading per pixel
	 *
	 *  Special shader for metallic surfaces.
     */
	public final static int aiShadingMode_CookTorrance = 0x8;

    /** No shading at all. Constant light influence of 1.0.
    */
	public final static int aiShadingMode_NoShading = 0x9;

	 /** Fresnel shading
     */
	public final static int aiShadingMode_Fresnel = 0xa;

};