package assimp;

public class aiAnimBehavior {
	/** The value from the default node transformation is taken */
	public static final int aiAnimBehaviour_DEFAULT = 0x0;

	/** The nearest key value is used without interpolation */
	public static final int aiAnimBehaviour_CONSTANT = 0x1;

	/**
	 * The value of the nearest two keys is linearly extrapolated for the
	 * current time value.
	 */
	public static final int aiAnimBehaviour_LINEAR = 0x2;

	/**
	 * The animation is repeated.
	 *
	 * If the animation key go from n to m and the current time is t, use the
	 * value at (t-n) % (|m-n|).
	 */
	public static final int aiAnimBehaviour_REPEAT = 0x3;

}
