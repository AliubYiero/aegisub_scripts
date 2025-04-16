import { bundle } from 'luabundle';
import { mkdirSync, writeFileSync, readdirSync, watch } from 'fs';
import { basename, join, resolve, dirname, isAbsolute } from 'path';
import { debounce } from 'radash';

/** @type {string} filepath 项目入口文件, 打包后的文件名也会以该文件名命名 */
const entry = './src/append_style_to_text.lua';
/** @type {@import('luabundle').BundleOptions} bundleOptions 项目配置 */
const bundleOptions = {
	// 模块搜索地址
	paths: [ './src/?.lua', ...readdirSync( '../../include' ).map( path => `../../include/${ path }/?.lua` ) ],
	// 忽略导入的模块, 比如在 include 目录下的模块就不用打包进文件, 可以直接 require 使用
	ignoredModuleNames: [
		'karaskel', 'aegisub.util', 'aegisub.unicode', 'aegisub.clipboard', 'aegisub.re',
	],
};

// -----------------------------------------------
// 获取绝对路径地址
const filepath = resolve( entry );

// 日志打印
const logger = {
	info: ( ...msgs ) => console.info( `[INFO] [${ new Date().toLocaleString() }]`, ...msgs ),
	error: ( ...msgs ) => console.error( `[ERROR] [${ new Date().toLocaleString() }]`, ...msgs ),
	warn: ( ...msgs ) => console.warn( `[WARN] [${ new Date().toLocaleString() }]`, ...msgs ),
};
/**
 * 创建打包文件
 */
const createBundleLua = ( filepath, bundleOptions ) => {
	/**
	 *  生成打包后的 Lua 字符串
	 */
	const bundledLua = bundle( filepath, bundleOptions );
	const filename = basename( filepath );
	/**
	 *  生成打包后的文件
	 */
	mkdirSync( './dist', { recursive: true } );
	writeFileSync( join( './dist', filename ), bundledLua );
	
	logger.info( '文件打包成功' );
	logger.info( '文件路径:', join( './dist', filename ), '\n' );
};
createBundleLua( filepath, bundleOptions );

// 开启文件监听
// 检查文件是否是临时文件
const isTempFile = ( filename ) => filename.endsWith( '~' );
if ( process.argv.find( item => item === '--watch' ) ) {
	logger.info( '文件监听已开启' );
	const watchDirList = bundleOptions.paths.map( item => resolve( dirname( item ) ) );
	console.info( `正在监听以下路径:
\tat ${ watchDirList.join( '\n\tat ' ) }\n` );
	watchDirList.forEach( dir => {
		if ( !isAbsolute( dir ) ) {
			logger.warn( '监听到文件路径不是绝对路径, 无法进行监听...' );
			return;
		}
		
		const debouncedBundle = debounce(
			{ delay: 300 },
			( file ) => {
				logger.info( `${ file } 文件内容已修改，重新打包:` );
				createBundleLua( filepath, bundleOptions );
			},
		); // 延迟 300ms 确保操作稳定
		
		const watcher = watch( dir,
			{ persistent: true, recursive: true },
			( eventType, filename ) => {
				if ( eventType === 'change' && filename && !isTempFile( filename ) ) {
					debouncedBundle( filename );
				}
			} );
		
		watcher.on( 'error', err => logger.error( err ) );
		watcher.on( 'close', () => logger.info( '文件监听已关闭' ) );
	} );
}
