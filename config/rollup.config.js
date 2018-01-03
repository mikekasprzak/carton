import includePaths						from 'rollup-plugin-includepaths';

export default {
	'output': {
		'format': 'es'
	},
	'plugins': [
		includePaths({
			'paths': [
				'../external'
			],
			'extensions': ['.es.js'],
		}),
	]
};
