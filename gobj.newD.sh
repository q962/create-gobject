#! /usr/bin/bash
#
# new G_DECLARE_DERIVABLE_TYPE

function checkArg(){
	local outdir
	local ClassName
	local ParentClassName

	if [[ $# == 0 ]]; then
		read outdir ClassName ParentClassName
		if [ -z "$ParentClassName" ]; then
			ParentClassName=$ClassName
			ClassName=$outdir
			unset outdir
		fi
	elif [[ $# == 2 ]]; then
		ClassName=$1
		ParentClassName=$2
	elif [[ $# < 3 ]]; then
		echo "参数错误，请输入：outdir ClassName ParentClassName
		 	如果 filepath 为空或未设置则输出文件内容到Stdout
			否则在 filepath 中创建 ClassName.{h,c} 文件" >&2
		exit -1;
	else
		outdir=$1
		ClassName=$2
		ParentClassName=$3
	fi

	if [ -z "$ClassName" -o -z "$ParentClassName" ]; then
		echo "错误参数，空值：
				\$outdir: $outdir
				\$ClassName: $ClassName
				\$ParentClassName: $ParentClassName" >&2
		exit -1;
	fi

	echo "$outdir" "$ClassName" "$ParentClassName"
}

function main(){

	local outdir=$1
	local ClassName=$2
	local ParentClassName=$3

	if [ -z "$ParentClassName" ]; then
		ParentClassName=$ClassName
		ClassName=$outdir
		unset outdir
		no_outdir=" "
	fi

	local Class_Name=$(echo $ClassName | sed -e 's/\([[:upper:]]\)/_\1/g' -e 's/^.//')
	local class_name=${Class_Name,,}
	local CLASS_NAME=${class_name^^}
	local parent_Class_Name=$(echo $ParentClassName | sed -e 's/\([[:upper:]]\)/_\1/g' -e 's/^.//')
	local parent_class_name=${parent_Class_Name,,}
	local parent_CLASS_NAME=${parent_Class_Name^^}
	local PARENT_TYPE_CLASS_NAME=$(echo $parent_Class_Name | sed -e 's/_/_type_/1' -e 's/[a-z]/\u&/g')
	local namespace=$(echo $Class_Name | cut -d_ -f 1)
	local NAMESPACE=${namespace^^}

	# 后接 ‘/’ 去除 './'
	local stdafx_path=$(realpath --relative-to=`dirname "${outdir}"` "." )
	if [ "$stdafx_path" != "." ]; then
		stdafx_path=$stdafx_path/
	fi

###############################
	local code_snippets_header="${outdir:+"#pragma once"}

${outdir:+"#include \"stdafx.h\""}

${outdir:+"G_BEGIN_DECLS"}

#if 1 // gobject definition

G_DECLARE_DERIVABLE_TYPE( ${ClassName}, ${class_name}, ${NAMESPACE}, ${CLASS_NAME:${#NAMESPACE}+1}, ${ParentClassName} )

struct _${ClassName}Class {
	${ParentClassName}Class parent_instance;
};

${ClassName}* ${class_name}_new();

${outdir:+"#endif"}

${outdir:+"G_END_DECLS"}
"
###############################

	local code_snippets_source="${outdir:+"#include \"${ClassName}.h\""}

${outdir:+"#if 1 // gobject definition"}

typedef struct {
	int spik;
} ${ClassName}Private;

enum {
	${no_outdir:+${CLASS_NAME}_}PROP_0,
	${no_outdir:+${CLASS_NAME}_}PROP_N,
};

G_DEFINE_TYPE_WITH_PRIVATE( ${ClassName}, ${class_name}, ${parent_class_name}_get_type() )

#define SELF_PRIVATE ${class_name}_get_instance_private
#define SELFDATAVAL( SELF, NAME ) ${ClassName}Private* NAME = SELF_PRIVATE( ( SELF ) )
#define SELFDATA2( SELF ) ( ( ${ClassName}Private* )SELF_PRIVATE( ( SELF ) ) )
#define SELFDATA SELFDATA2( self )

#if 1 // static function

#endif

#if 1 // base class virtual function

static void ${class_name}_constructed( GObject* object ) {
	${ClassName}* self = ( ${ClassName}* )object;

	G_OBJECT_CLASS (${class_name}_parent_class)->constructed(object);
}

static void ${class_name}_dispose( GObject* object ) {
	${ClassName}* self = ( ${ClassName}* )object;

	G_OBJECT_CLASS (${class_name}_parent_class)->dispose(object);
}

static void ${class_name}_finalize( GObject* object ) {
	${ClassName}* self = ( ${ClassName}* )object;

	G_OBJECT_CLASS (${class_name}_parent_class)->finalize(object);
}

static void ${class_name}_init(${ClassName}* self) {
	${ClassName}Private* priv = SELFDATA;
}

static void ${class_name}_class_init(${ClassName}Class* klass) {
	GObjectClass* base_class = (GObjectClass*)klass;
	${ParentClassName}Class* parent_class = (${ParentClassName}Class*)klass;

	base_class->constructed = ${class_name}_constructed;
	base_class->dispose = ${class_name}_dispose;
	base_class->finalize = ${class_name}_finalize;
}

#endif

#if 1 // public function

${ClassName}* ${class_name}_new() {
	${ClassName}* self = g_object_new( ${class_name}_get_type(), NULL );
	return self;
}

#endif

#endif
"
###############################

	if [ -n "$outdir" ]; then
		mkdir -p ${outdir}
		echo "$code_snippets_header" > ${outdir}/${ClassName}.h
		echo "$code_snippets_source" > ${outdir}/${ClassName}.c
		exit 0
	fi

	echo "$code_snippets_header""$code_snippets_source" | uniq
	exit 0
}

main $(checkArg "$@")