#!/usr/bin/env node

const commandLineArgs = require('command-line-args');
const winston = require('winston');

var remark = require('remark');
var toc = require('remark-toc');
var fs = require('fs');

var localFile = '';

// Logger
const myFormat = winston.format.printf(({
    level,
    message,
    label,
    timestamp
}) => {
    return `${timestamp} ${level}: ${message}`;
});

const logger = winston.createLogger({
    format: winston.format.combine(
        winston.format.timestamp(),
        myFormat
    ),
    transports: [new winston.transports.Console()]
});

var inputFile = '';
var outputFile = '';

// "Man Pages"
function helpOutput() {
    const commandLineUsage = require('command-line-usage');

    const sections = [{
            header: 'Scrivener Post Processing Script',
            content: 'Executes some post processing scripts after Scrivener compilation (e.g. TOC generation, Footnote processing...)'
        },
        {
            header: 'Options',
            optionList: [{
                    name: 'input-file',
                    alias: 'i',
                    typeLabel: '{underline file}',
                    description: 'File to be processed'
                }, {
                    name: 'output-file',
                    alias: 'o',
                    typeLabel: '{underline file}',
                    description: 'Processed file'
                },
                {
                    name: 'help',
                    alias: 'h',
                    description: 'Print this usage guide.'
                }
            ]
        }
    ];

    const usage = commandLineUsage(sections);
    console.log(usage);
    process.exit(0);
}

// Input Check
function checkOptions() {
    logger.info('===== Checking Input Parameters =====');
    const optionDefinitions = [{
            name: 'input-file',
            alias: 'i',
            type: String
        },
        {
            name: 'output-file',
            alias: 'o',
            type: String
        },
        {
            name: 'help',
            alias: 'h',
            type: Boolean
        }
    ]

    const options = commandLineArgs(optionDefinitions);

    if (Object.keys(options).length === 0) {
        logger.error("No input file and output file specified. Use -h or --help for further information");
        process.exit(4);
    }

    if (options.help) {
        helpOutput();
        process.exit(0);
    }

    if (!options['input-file']) {
        logger.error("No input file specified. Use -h or --help for further information");
        process.exit(4);
    }

    if (!options['output-file']) {
        logger.error("No output file specified. Use -h or --help for further information");
        process.exit(4);
    }

    inputFile = options['input-file'];
    outputFile = options['output-file'];

    logger.info('Reading from ' + inputFile);
    logger.info('Writing to ' + outputFile);
}


function createToc() {
    logger.info();
    logger.info('===== Creating ToC =====');
    logger.info('Creating ToC')
    remark()
        .use(toc, {
            tight: true
        })
        .process(localFile, function (err, file) {
            if (err) logger.error(err.message);
            localFile = file;
        });
}

function processFootNotes() {
    logger.info();
    logger.info('===== Transforming Foot Notes =====');
    var str = localFile;

    // Processing List at the End of the file first
    // So in the next step they get not caught by the links inside text processing
    var regex = /\[\^fn\d*\]: /gm;
    var res = str.replace(regex, function (x) {
        var target = '<a name="' +
            x.substring(2, x.lastIndexOf(']')) +
            '">\[' +
            x.substring(4, x.lastIndexOf(']')) +
            '\]</a>: ';
        logger.info('Processing footnote reference: ' + x + ' ==> ' + target);
        return target;
    });

    str = res;

    // Processing links inside text
    regex = /\[\^fn\d*\]/gm;
    // <sup>[19](#fn_corsauth)</sup>

    var res = str.replace(regex, function (x) {
        var target = '<sup>[' +
            x.substring(4, x.lastIndexOf(']')) +
            '](#' +
            x.substring(2, x.lastIndexOf(']')) +
            ')</sup>';
        logger.info('Processing text reference: ' + x + ' ==> ' + target);
        return target;
    });

    localFile = res;
}

function fixImageURL() {
    logger.info();
    logger.info('===== Fixing Image References =====');
    var fileAnchorArray = [];
    var str = localFile;
    var regex = /!\[\]\[.*\]/gm;
    // ![][ImageName]

    var res = str.replace(regex, function (x) {
        var anchorName = x;

        anchorName = anchorName.replace('![][', '');
        anchorName = anchorName.substr(0, anchorName.length - 1);
        logger.info('Processing [' + anchorName + ']');

        var fileAnchorRegex = new RegExp('\\[' + anchorName + '\\]:\\s.*\\n', 'gm');
        var anchorArray = str.match(fileAnchorRegex);

        if (anchorArray === null) {
            logger.error('No Image Anchor found for [' + anchorName + '] -> Exiting');
            process.exit(4);
        }

        if (anchorArray.length != 1) {
            logger.error('Found multiple matches for the Image Anchor [' + anchorName + '] -> Exiting');
            process.exit(4);
        }

        var anchorDefinition = anchorArray[0];
        logger.info("Extracting data from: " + anchorDefinition.substr(0, anchorDefinition.length - 1)); // Removing the trailing \n

        var fileName = anchorDefinition.replace('[' + anchorName + ']: ', '');
        fileName = fileName.substr(0, fileName.indexOf(' '));

        logger.info('Image name: ' + fileName);

        var target = '![](' +
            fileName +
            ')';
        logger.info('Transforming Reference: ' + x + ' ==> ' + target);

        fileAnchorArray.push(anchorDefinition);
        return target;
    });

    logger.info();
    logger.info('===== Removing File Anchors from File =====');

    for (var i = 0; i < fileAnchorArray.length; i++) {
        logger.info("Removing: " + fileAnchorArray[i].substr(0, fileAnchorArray[i].length - 1)); // Removing the trailing \n
        res = res.replace(fileAnchorArray[i], '');
    }

    localFile = res;
}

////// MAIN //////
checkOptions();

// Read File in local representation
localFile = fs.readFileSync(inputFile, 'utf8');

processFootNotes();
fixImageURL();
createToc();

fs.writeFileSync(outputFile, localFile);
logger.info();
logger.info(outputFile + ' succesfully created');