import includePaths						from 'rollup-plugin-includepaths';

export default {
	'output': {
		'format': 'es'
	},
	'plugins': [
		includePaths({
			'paths': [
				'.output/external',
				'.output/src'
			],
			'extensions': ['.es.js'],
		}),
	]
};
