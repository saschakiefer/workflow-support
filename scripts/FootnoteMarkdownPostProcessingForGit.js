#!/usr/bin/env node

const commandLineArgs = require('command-line-args');
const winston = require('winston');

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
            header: 'Footnote Post Processing Script',
            content: 'post processing script, that turns a custom inline footnote string with the format {{fn: }} into a numbered footnote list, that is also compatible with git.'
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

    var footnoteList = "";
    var counter = 1;


    // Find inline Footnotes in the format 
    // ((fn: <content>))
    var regex = /\{\{fn:.*\}\}/gm;
    var res = str.replace(regex, function (x) {
        var target = '<sup>[' + counter + '](#fn' + counter + ')</sup>';
        // logger.info('Processing text reference: ' + x + ' ==> ' + target);

        var footnoteString = x.substring(5, x.length - 2).trim();
        footnoteString = '<a name="fn' + counter + '">[' + counter + ']</a>: ' + footnoteString + "\n";
        // logger.info('Footnote: ' + footnoteString);

        footnoteList = footnoteList + footnoteString;
        counter++;
        return target;
    });

    if (counter > 0) {
        counter = counter - 1
    }

    logger.info(counter + ' Footnote(s) processed');
    footnoteList = '\n\n---\n\n' + footnoteList;
    localFile = res + footnoteList;
}

////// MAIN //////
checkOptions();

// Read File in local representation
localFile = fs.readFileSync(inputFile, 'utf8');

processFootNotes();

fs.writeFileSync(outputFile, localFile);
logger.info();
logger.info(outputFile + ' succesfully created');